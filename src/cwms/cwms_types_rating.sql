/*
drop type stream_rating_t;
drop type rating_tab_t;
drop type rating_t;
drop type rating_ind_parameter_tab_t;
drop type rating_ind_parameter_t;
drop type rating_value_tab_t;
drop type rating_value_t;
drop type abs_rating_ind_parameter_t;
drop type rating_value_note_tab_t;
drop type rating_value_note_t;
drop type rating_spec_t;
drop type rating_template_t;
drop type rating_ind_param_spec_tab_t;
drop type rating_ind_param_spec_t;
*/
create type rating_ind_param_spec_t as object(
   parameter_position           number(1),
   parameter_id                 varchar2(49),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   
   constructor function rating_ind_param_spec_t(
      p_ind_param_spec_code in number)
   return self as result,
   
   constructor function rating_ind_param_spec_t(
      p_xml in xmltype)
   return self as result,
   
   member procedure validate_obj,
            
   member function get_parameter_code(
      p_office_id in varchar2)
   return number,
   
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
    
   member function get_in_range_rating_code
   return number,
   
   member function get_out_range_low_rating_code
   return number,
   
   member function get_out_range_high_rating_code
   return number,
   
   member procedure store(
      p_template_code  in number,
      p_fail_if_exists in varchar2),
      
   member function to_xml
   return xmltype,      
      
   member function to_clob
   return clob      
);
/
show errors;

create type body rating_ind_param_spec_t
as
   constructor function rating_ind_param_spec_t(
      p_ind_param_spec_code in number)
   return self as result
   is
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select *
              from at_rating_ind_param_spec
             where ind_param_spec_code = p_ind_param_spec_code
         )
      loop
         self.parameter_position := rec.parameter_position;
         self.parameter_id := cwms_util.get_parameter_id(rec.parameter_code);
         
         select rating_method_id 
           into self.in_range_rating_method 
           from cwms_rating_method 
          where rating_method_code = rec.in_range_rating_method;
          
         select rating_method_id 
           into self.out_range_low_rating_method 
           from cwms_rating_method 
          where rating_method_code = rec.out_range_low_rating_method;
          
         select rating_method_id 
           into self.out_range_high_rating_method 
           from cwms_rating_method
          where rating_method_code = rec.out_range_high_rating_method;
      end loop;
      self.validate_obj;
      return;         
   end;
   
   constructor function rating_ind_param_spec_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml xmltype;
   begin
      if p_xml.existsnode('//ind-parameter-spec') = 1 then
         l_xml := p_xml.extract('//ind-parameter-spec');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <ind-parameter-spec> element');
      end if;
      if l_xml.existsnode('/ind-parameter-spec/@position') = 1 then
         self.parameter_position := l_xml.extract('/ind-parameter-spec/@position').getnumberval;
      else
         cwms_err.raise(
            'ERROR',
            'Required "position" attribute not found in <ind-parameter-spec> element');
      end if;
      if l_xml.existsnode('/ind-parameter-spec/parameter') = 1 then
         self.parameter_id := l_xml.extract('/ind-parameter-spec/parameter/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<parameter> element not found under <ind-parameter-spec> element');
      end if;
      if l_xml.existsnode('/ind-parameter-spec/in-range-method') = 1 then
         self.in_range_rating_method := l_xml.extract('/ind-parameter-spec/in-range-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<in-range-method> element not found under <ind-parameter-spec> element');
      end if;
      if l_xml.existsnode('/ind-parameter-spec/out-range-low-method') = 1 then
         self.out_range_low_rating_method := l_xml.extract('/ind-parameter-spec/out-range-low-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<out-range-low-method> element not found under <ind-parameter-spec> element');
      end if;
      if l_xml.existsnode('/ind-parameter-spec/out-range-high-method') = 1 then
         self.out_range_high_rating_method := l_xml.extract('/ind-parameter-spec/out-range-high-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<out-range-high-method> element not found under <ind-parameter-spec> element');
      end if;
      self.validate_obj;
      return;
   end;
   
   member procedure validate_obj
   is
      l_code number(10);
   begin
      ------------------------
      -- parameter position --
      ------------------------
      if self.parameter_position is null or self.parameter_position < 1 then
         cwms_err.raise(
            'INVALID_ITEM',
            nvl(to_char(self.parameter_position), '<NULL>'),
            'parameter position');
      end if;
      ------------------
      -- parameter_id --
      ------------------
      begin
         select base_parameter_code
           into l_code
           from cwms_base_parameter
          where base_parameter_id = cwms_util.get_base_id(self.parameter_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_PARAM_ID',
               self.parameter_id);
      end;
      ----------------------------
      -- in_range_rating_method --
      ----------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.in_range_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.in_range_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
      ---------------------------------
      -- out_range_low_rating_method --
      ---------------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.out_range_low_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.out_range_low_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
      ----------------------------------
      -- out_range_high_rating_method --
      ----------------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.out_range_high_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.out_range_high_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
   end;
   
   member function get_parameter_code(
      p_office_id in varchar2)
   return number
   is
      l_base_param_id varchar2(16) := cwms_util.get_base_id(self.parameter_id);
      l_sub_param_id  varchar2(32) := cwms_util.get_sub_id(self.parameter_id);
   begin
      return cwms_ts.get_parameter_code(l_base_param_id, l_sub_param_id, p_office_id, 'T');
   end;
   
   member function get_rating_code(
      p_rating_id in varchar2)
   return number 
   is
      l_rating_code number;
   begin
      select rating_method_code
        into l_rating_code
        from cwms_rating_method
       where rating_method_id = upper(p_rating_id);
       
      return l_rating_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating method identifier');             
   end;
   
   member function get_in_range_rating_code
   return number
   is
   begin
      return get_rating_code(self.in_range_rating_method);
   end;
   
   member function get_out_range_low_rating_code
   return number
   is
   begin
      return get_rating_code(self.out_range_low_rating_method);
   end;
   
   member function get_out_range_high_rating_code
   return number
   is
   begin
      return get_rating_code(self.out_range_high_rating_method);
   end;
   
   member procedure store(
      p_template_code  in number,
      p_fail_if_exists in varchar2)
   is
      l_rec           at_rating_ind_param_spec%rowtype;
      l_office_id     varchar2(16);
      l_parameters_id varchar2(256);
      l_version       varchar2(32);
   begin
      l_rec.template_code   := p_template_code;
      l_rec.parameter_position := self.parameter_position;
      
      select o.office_id,
             lt.parameters_id,
             lt.version
        into l_office_id,
             l_parameters_id,
             l_version
        from at_rating_template lt,
             cwms_office o
       where lt.template_code = p_template_code
         and o.office_code = lt.office_code;
      
      begin
         select *
           into l_rec
           from at_rating_ind_param_spec
          where template_code = l_rec.template_code
            and parameter_position = l_rec.parameter_position;
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Independent rating parameter specification',
               l_office_id 
               || '/' 
               || l_parameters_id
               || '.'
               || l_version 
               || ' parameter ' 
               || self.parameter_position);
         end if;            
         l_rec.parameter_code               := self.get_parameter_code(l_office_id);
         l_rec.in_range_rating_method       := self.get_in_range_rating_code;
         l_rec.out_range_low_rating_method  := self.get_out_range_low_rating_code;
         l_rec.out_range_high_rating_method := self.get_out_range_high_rating_code;
         
         update at_rating_ind_param_spec
            set row = l_rec
          where ind_param_spec_code = l_rec.ind_param_spec_code;
      exception
         when no_data_found then
            l_rec.ind_param_spec_code          := cwms_seq.nextval;
            l_rec.parameter_code               := self.get_parameter_code(l_office_id);
            l_rec.in_range_rating_method       := self.get_in_range_rating_code;
            l_rec.out_range_low_rating_method  := self.get_out_range_low_rating_code;
            l_rec.out_range_high_rating_method := self.get_out_range_high_rating_code;
            
            insert
              into at_rating_ind_param_spec
            values l_rec;
      end;
   end;      
      
   member function to_xml
   return xmltype
   is
   begin
      return xmltype('<ind-parameter-spec position="'||self.parameter_position||'">'
         ||'<parameter>'||self.parameter_id||'</parameter>'
         ||'<in-range-method>'||self.in_range_rating_method||'</in-range-method>'
         ||'<out-range-low-method>'||self.out_range_low_rating_method||'</out-range-low-method>'
         ||'<out-range-high-method>'||self.out_range_high_rating_method||'</out-range-high-method>'
         ||'</ind-parameter-spec>');
   end;      
      
   member function to_clob
   return clob
   is
      l_xml xmltype := self.to_xml;
   begin
      return l_xml.getclobval;
   end;      
end;
/
show errors;

create type rating_ind_param_spec_tab_t as table of rating_ind_param_spec_t;
/
show errors;
 
create type rating_template_t as object(
   office_id         varchar2(16),
   parameters_id     varchar2(256),
   version           varchar2(32),
   ind_parameters    rating_ind_param_spec_tab_t,
   dep_parameter_id  varchar2(49),
   description       varchar2(256),
   
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_param_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result,
   
   constructor function rating_template_t(
      p_template_code in number)
   return self as result,
   
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result,
   
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result,
   
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result,      
   
   member procedure init(
      p_template_code in number),
   
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2),
      
   member procedure validate_obj,
         
   member function get_office_code
   return number,
   
   member function get_dep_parameter_code
   return number,
   
   member procedure store(
      p_fail_if_exists in varchar2),
      
   member function to_xml
   return xmltype,      
      
   member function to_clob
   return clob,      

   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number default null)
   return number,      
      
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number,      
      
   static function get_template_code(
      p_template_id in varchar2,
      p_office_id   in varchar2 default null)
   return number      
);
/
show errors;

create type body rating_template_t
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
      p_ind_parameters    in rating_ind_param_spec_tab_t,
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
            self.parameters_id := self.parameters_id || ',';
         end if;
      end loop;
      self.parameters_id := self.parameters_id || ';' || dep_parameter_id;
   end;
   
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result
   is
   begin
      init(p_office_id, p_parameters_id, p_version);
   end;
   
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, '.');
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      init(p_office_id, l_parts(1), l_parts(2));
   end;
   
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml   xmltype;
      l_parts str_tab_t;
      i       binary_integer;
   begin
      if p_xml.existsnode('//rating-template') = 1 then
         l_xml := p_xml.extract('//rating-template');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/@office-id') = 1 then
         self.office_id := l_xml.extract('/rating-template/@office-id').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Required "office-id" attribute is not found in <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/parameters-id') = 1 then
         self.parameters_id := l_xml.extract('/rating-template/parameters-id/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<parameters-id> element is not found under <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/version') = 1 then
         self.version := l_xml.extract('/rating-template/version/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<version> element is not found under <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/dep-parameter') = 1 then
         self.dep_parameter_id := l_xml.extract('/rating-template/dep-parameter/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            '<dep-parameter> element is not found under <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/ind-parameter-specs') = 1 then
         l_parts := cwms_util.split_text(
            l_xml.extract('/rating-template/ind-parameter-specs/ind-parameter-spec').getstringval,
            '</ind-parameter-spec>');
         self.ind_parameters := rating_ind_param_spec_tab_t();
         self.ind_parameters.extend(l_parts.count - 1);   
         for i in 1..l_parts.count - 1 loop
            self.ind_parameters(i) := rating_ind_param_spec_t(
               l_xml.extract('/rating-template/ind-parameter-specs/ind-parameter-spec['||i||']'));
         end loop;         
      else
         cwms_err.raise(
            'ERROR',
            '<ind-parameter-specs> element is not found under <rating-template> element');
      end if;         
      if l_xml.existsnode('/rating-template/description') = 1 then
         begin
            self.description := l_xml.extract('/rating-template/description/text()').getstringval;
         exception
            when others then if sqlcode = -30625 then null; else raise; end if;
         end;
      end if;
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
         self.ind_parameters    := rating_ind_param_spec_tab_t();
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
      ----------------------
      -- dep_parameter_id --
      ----------------------
      begin
         select base_parameter_code
           into l_code
           from cwms_base_parameter
          where base_parameter_id = cwms_util.get_base_id(self.dep_parameter_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_PARAM_ID',
               self.dep_parameter_id);
      end;
      -------------------
      -- parameters_id --
      -------------------
      l_parts := cwms_util.split_text(self.parameters_id, ';');
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            self.parameters_id,
            'Rating template parameters identifier');
      end if;
      if l_parts(2) != self.dep_parameter_id then
         cwms_err.raise(
            'ERROR',
            'Rating template dependent parameter ('
            ||self.dep_parameter_id
            ||') does not agree with parameters identifier ('
            ||self.parameters_id
            ||')');
      end if;
      l_parts := cwms_util.split_text(l_parts(1), ',');
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
         if l_parts(i) != self.ind_parameters(i).parameter_id then
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
            self.office_id || '/' || self.parameters_id || '.' || self.version);
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
      p_office_code   in number default null)
   return number
   is
      l_office_code   number(10) := nvl(p_office_code, cwms_util.user_office_code);
      l_template_code number(10);
   begin
      select template_code
        into l_template_code
        from at_rating_template
       where office_code = l_office_code
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
             where office_code = l_office_code;
             
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating template',
               l_office_id 
               || '/' 
               || p_parameters_id 
               || '.' 
               || p_version);
         end;
   end;      
      
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, '.');
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
         
   static function get_template_code(
      p_template_id in varchar2,
      p_office_id   in varchar2 default null)
   return number
   is
   begin
      return rating_template_t.get_template_code(
         p_template_id,
         cwms_util.get_office_code(p_office_id));
   end;      
   
end;
/
show errors;

create type rating_spec_t as object(
   office_id                    varchar2(16),
   location_id                  varchar2(49),
   template_id                  varchar2(289), -- template.parameters_id + template.version
   version                      varchar2(32),
   source_agency_id             varchar2(32),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   active_flag                  varchar2(1),
   auto_update_flag             varchar2(1),
   auto_activate_flag           varchar2(1),
   auto_migrate_ext_flag        varchar2(1),
   ind_rounding_specs           str_tab_t,
   dep_rounding_spec            varchar2(10),
   description                  varchar2(256),
   
   constructor function rating_spec_t(
      p_rating_spec_code in number)
   return self as result,
         
   constructor function rating_spec_t(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return self as result,      
         
   constructor function rating_spec_t(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return self as result,
   
   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result,
   
   member procedure init(
      p_rating_spec_code in number),
      
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null),
            
   member procedure validate_obj,
         
   member function get_location_code
   return number,
   
   member function get_template_code
   return number,
   
   member function get_source_agency_code
   return number,
   
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   
   member function get_in_range_rating_code
   return number,     
   
   member function get_out_range_low_rating_code
   return number,     
   
   member function get_out_range_high_rating_code
   return number,
   
   member procedure store(
      p_fail_if_exists in varchar2),     

   member function to_clob
   return clob,
   
   member function to_xml
   return xmltype,
            
   static function get_rating_spec_code(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return number,      
         
   static function get_rating_spec_code(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return number
);
/
show errors;

create type body rating_spec_t
as
   constructor function rating_spec_t(
      p_rating_spec_code in number)
   return self as result
   is
   begin
      init(p_rating_spec_code);
      return;
   end;
         
   constructor function rating_spec_t(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return self as result
   is
   begin
      init(p_location_id, p_template_id, p_version, p_office_id);
      return;
   end;      
         
   constructor function rating_spec_t(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_rating_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating specification');
      end if;
      init(l_parts(1), l_parts(2)||'.'||l_parts(3), l_parts(4), p_office_id);
      return;
   end;

   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml            xmltype;
      l_rating_spec_id varchar2(372);
      l_parts          str_tab_t;
      l_text           varchar2(64);
   begin
      if p_xml.existsnode('//rating-spec') = 1 then
         l_xml := p_xml.extract('//rating-spec');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/@office-id') = 1 then
         self.office_id := l_xml.extract('/rating-spec/@office-id').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Attribute "office-id" not found in <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/rating-spec-id') = 1 then
         l_rating_spec_id := l_xml.extract('/rating-spec/rating-spec-id/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <rating-spec-id> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/template-id') = 1 then
         self.template_id := l_xml.extract('/rating-spec/template-id/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <template-id> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/location-id') = 1 then
         self.location_id := l_xml.extract('/rating-spec/location-id/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <location-id> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/version') = 1 then
         self.version := l_xml.extract('/rating-spec/version/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <version> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/source-agency') = 1 then
         begin
            self.source_agency_id := l_xml.extract('/rating-spec/source-agency/text()').getstringval;
         exception
            when others then if sqlcode = -30625 then null; else raise; end if;
         end;
      end if;
      if l_xml.existsnode('/rating-spec/in-range-method') = 1 then
         self.in_range_rating_method := l_xml.extract('/rating-spec/in-range-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <in-range-method> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/out-range-low-method') = 1 then
         self.out_range_low_rating_method := l_xml.extract('/rating-spec/out-range-low-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <out-range-high-method> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/out-range-high-method') = 1 then
         self.out_range_high_rating_method := l_xml.extract('/rating-spec/out-range-high-method/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <out-range-high-method> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/active') = 1 then
         l_text := l_xml.extract('/rating-spec/active/text()').getstringval;
         if l_text in ('true', 'false') then
            self.active_flag := upper(substr(l_text, 1, 1));
         else
            cwms_err.raise(
               'ERROR',
               'Invlaid value for <active> element under <rating-spec> element: '
               ||l_text
               ||', should be true or false');
         end if;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <active> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/auto-update') = 1 then
         l_text := l_xml.extract('/rating-spec/auto-update/text()').getstringval;
         if l_text in ('true', 'false') then
            self.auto_update_flag := upper(substr(l_text, 1, 1));
         else
            cwms_err.raise(
               'ERROR',
               'Invlaid value for <auto-update> element under <rating-spec> element: '
               ||l_text
               ||', should be true or false');
         end if;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <auto-update> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/auto-activate') = 1 then
         l_text := l_xml.extract('/rating-spec/auto-activate/text()').getstringval;
         if l_text in ('true', 'false') then
            self.auto_activate_flag := upper(substr(l_text, 1, 1));
         else
            cwms_err.raise(
               'ERROR',
               'Invlaid value for <auto-activate> element under <rating-spec> element: '
               ||l_text
               ||', should be true or false');
         end if;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <auto-activate> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/auto-migrate-extension') = 1 then
         l_text := l_xml.extract('/rating-spec/auto-migrate-extension/text()').getstringval;
         if l_text in ('true', 'false') then
            self.auto_migrate_ext_flag := upper(substr(l_text, 1, 1));
         else
            cwms_err.raise(
               'ERROR',
               'Invlaid value for <auto-migrate-extension> element under <rating-spec> element: '
               ||l_text
               ||', should be true or false');
         end if;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <auto-migrate-extension> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/ind-rounding-specs') = 1 then
         l_parts := cwms_util.split_text(
            l_xml.extract('/rating-spec/ind-rounding-specs/ind-rounding-spec').getstringval,
            '</ind-rounding-spec>');
         self.ind_rounding_specs := str_tab_t();
         self.ind_rounding_specs.extend(l_parts.count-1);
         for i in 1..l_parts.count-1 loop
            if l_xml.existsnode('/rating-spec/ind-rounding-specs/ind-rounding-spec['||i||']/@position') = 1 then
               if l_xml.extract('/rating-spec/ind-rounding-specs/ind-rounding-spec['||i||']/@position').getnumberval != i then
                  cwms_err.raise(
                     'ERROR',
                     'Attribute "position" is '
                     ||l_xml.extract('/rating-spec/ind-rounding-specs/ind-rounding-spec['||i||']/@position').getnumberval
                     ||' on <ind-rounding-spec> number '||i||' under <rating-spec> element, should be '||i);
               end if;
            else
               cwms_err.raise(
                  'ERROR',
                  'Missing "position" attribute on <ind-rounding-spec> number '||i||' under <rating-spec> element');
            end if;
            self.ind_rounding_specs(i) := l_xml.extract('/rating-spec/ind-rounding-specs/ind-rounding-spec['||i||']/text()').getstringval;
         end loop;            
      else
         cwms_err.raise(
            'ERROR',
            'Missing <ind-rounding-specs> element under <rating-spec> element');
      end if;
      if l_xml.existsnode('/rating-spec/dep-rounding-spec') = 1 then
         self.dep_rounding_spec := l_xml.extract('/rating-spec/dep-rounding-spec/text()').getstringval;
      else
         cwms_err.raise(
            'ERROR',
            'Missing <dep-rounding-spec> element under <rating-spec> element');
      end if;
      
      if l_xml.existsnode('/rating-spec/description') = 1 then
         begin
            self.description := l_xml.extract('/rating-spec/description/text()').getstringval;
         exception
            when others then if sqlcode = -30625 then null; else raise; end if;
         end;
      end if;
      l_parts := cwms_util.split_text(l_rating_spec_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise('ERROR', 'Invalid value for <rating-spec-id> element');
      end if;
      if l_parts(1) != self.location_id then
         cwms_err.raise(
            'ERROR',
            '<rating-spec-id> and <location-id> elements do not agree');
      end if;
      if l_parts(2)||'.'||l_parts(3) != self.template_id then
         cwms_err.raise(
            'ERROR',
            '<rating-spec-id> and <template-id> elements do not agree');
      end if;
      if l_parts(4) != self.version then
         cwms_err.raise(
            'ERROR',
            '<rating-spec-id> and <version> elements do not agree');
      end if;
      self.validate_obj;
      return;
   end;
            
   member procedure init(
      p_rating_spec_code in number)
   is
      l_template_parameters_id varchar2(256);
      l_template_version       varchar2(32);
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select * 
              from at_rating_spec
             where rating_spec_code = p_rating_spec_code
         )
      loop
         self.location_id           := cwms_util.get_location_id(rec.location_code, 'F');
         self.version               := rec.version;
         self.active_flag           := rec.active_flag;
         self.auto_update_flag      := rec.auto_update_flag;
         self.auto_activate_flag    := rec.auto_activate_flag;
         self.auto_migrate_ext_flag := rec.auto_migrate_ext_flag;
         self.dep_rounding_spec     := rec.dep_rounding_spec;
         self.description           := rec.description;
         
         select lt.parameters_id,
                lt.version,
                o.office_id
           into l_template_parameters_id,
                l_template_version,
                self.office_id
           from at_rating_template lt,
                cwms_office o
          where lt.template_code = rec.template_code
            and o.office_code = lt.office_code;
            
         self.template_id := l_template_parameters_id || '.' || l_template_version;             
          
         select loc_group_id
           into self.source_agency_id
           from at_loc_group
          where loc_group_code = rec.source_agency_code;
          
         select rating_method_id
           into self.in_range_rating_method
           from cwms_rating_method
          where rating_method_code = rec.in_range_rating_method;                    
          
         select rating_method_id
           into self.out_range_low_rating_method
           from cwms_rating_method
          where rating_method_code = rec.out_range_low_rating_method;                    
          
         select rating_method_id
           into self.out_range_high_rating_method
           from cwms_rating_method
          where rating_method_code = rec.out_range_high_rating_method;                    
        
         self.ind_rounding_specs := str_tab_t();
         for rec2 in
            ( select rounding_spec
                from at_rating_ind_rounding
               where rating_spec_code = rec.rating_spec_code
            order by parameter_position
            )
         loop
            self.ind_rounding_specs.extend;
            self.ind_rounding_specs(self.ind_rounding_specs.count) := rec2.rounding_spec;
         end loop;  
      end loop;
      self.validate_obj;         
   end;      
      
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   is
      l_rating_spec_code number(10);
   begin
      l_rating_spec_code := rating_spec_t.get_rating_spec_code(
         p_location_id,
         p_template_id,
         p_version,
         p_office_id);
         
      init(l_rating_spec_code);         
   end;      
   
   member procedure validate_obj
   is
      l_code     number(10);
      l_template rating_template_t;
      
      -------------------------------------------------------
      -- local routine to validate 10-digit rounding specs --
      -------------------------------------------------------
      procedure validate_rounding_spec(
         p_rounding_spec in varchar2)
      is
         l_number number;
      begin
         l_number := to_number(p_rounding_spec);
         if p_rounding_spec is null or length(p_rounding_spec) != 10 then
            cwms_err.raise('ERROR', '');
         end if;
      exception
         when others then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(p_rounding_spec, '<NULL>'),
               'USGS-style rounding specification'); 
      end;         
   begin
      ---------------------------
      -- check for null fields --
      ---------------------------
      if self.office_id is null then
         cwms_err.raise(
            'ERROR', 
            'Office identifier cannot be null in rating specification');  
      end if;
      if self.location_id is null then
         cwms_err.raise(
            'ERROR', 
            'Location identifier cannot be null in rating specification');  
      end if;
      if self.template_id is null then
         cwms_err.raise(
            'ERROR', 
            'Template identifier cannot be null in rating specification');  
      end if;
      if self.version is null then
         cwms_err.raise(
            'ERROR', 
            'Version cannot be null in rating specification');  
      end if;
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
      -----------------
      -- location_id --
      -----------------
      l_code := cwms_loc.get_location_code(self.office_id, self.location_id);
      -----------------
      -- template_id --
      -----------------
      l_template := rating_template_t(self.office_id, self.template_id); -- validiates on construction
      ----------------------
      -- source_agency_id --
      ----------------------
      l_code := self.get_source_agency_code;
      ----------------------------
      -- in_range_rating_method --
      ----------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.in_range_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.in_range_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
      ---------------------------------
      -- out_range_low_rating_method --
      ---------------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.out_range_low_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.out_range_low_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
      ----------------------------------
      -- out_range_high_rating_method --
      ----------------------------------
      begin
         select rating_method_code
           into l_code
           from cwms_rating_method
          where rating_method_id = upper(self.out_range_high_rating_method);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.out_range_high_rating_method, '<NULL>'),
               'CWMS rating method');
      end;
      --------------------
      -- boolean fields --
      --------------------
      if cwms_util.return_true_or_false(self.active_flag) then null; end if;
      if cwms_util.return_true_or_false(self.auto_update_flag) then null; end if;
      if cwms_util.return_true_or_false(self.auto_activate_flag) then null; end if;
      if cwms_util.return_true_or_false(self.auto_migrate_ext_flag) then null; end if;
      --------------------
      -- rounding specs --
      --------------------
      if self.ind_rounding_specs is null then
         cwms_err.raise(
            'ERROR',
            'Independent rounding specifications cannot be null');
      end if;
      for i in 1..self.ind_rounding_specs.count loop
         validate_rounding_spec(self.ind_rounding_specs(i));
      end loop;
      validate_rounding_spec(self.dep_rounding_spec);
   end;
   
   member function get_location_code
   return number
   is
   begin
      return cwms_loc.get_location_code(self.office_id, self.location_id);
   end;
   
   member function get_template_code
   return number
   is
      l_template_code number;
      l_parts         str_tab_t;
   begin
      l_parts := cwms_util.split_text(self.template_id, '.');
      select template_code
        into l_template_code
        from at_rating_template
       where office_code = cwms_util.get_office_code(self.office_id)
         and upper(parameters_id) = upper(l_parts(1))
         and upper(version) = upper(l_parts(2));
         
      return l_template_code;          
   end;
   
   member function get_source_agency_code
   return number
   is
      l_source_agency_code number;
   begin
      if self.source_agency_id is not null then
         select lg.loc_group_code
           into l_source_agency_code
           from at_loc_group lg,
                at_loc_category lc
          where lc.loc_category_id = 'Agency Aliases'
            and lg.loc_category_code = lc.loc_category_code
            and lg.db_office_code in (get_location_code, cwms_util.db_office_code_all)
            and upper(lg.loc_group_id) = upper(self.source_agency_id);
      end if;
      return l_source_agency_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Agency Aliases location group',
            self.source_agency_id);               
   end;
   
   member function get_rating_code(
      p_rating_id in varchar2)
   return number 
   is
      l_rating_code number;
   begin
      select rating_method_code
        into l_rating_code
        from cwms_rating_method
       where rating_method_id = upper(p_rating_id);
       
      return l_rating_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating method identifier');             
   end;
   
   member function get_in_range_rating_code
   return number
   is
   begin
      return get_rating_code(self.in_range_rating_method);
   end;     
   
   member function get_out_range_low_rating_code
   return number
   is
   begin
      return get_rating_code(self.out_range_low_rating_method);
   end;     
   
   member function get_out_range_high_rating_code
   return number
   is
   begin
      return get_rating_code(self.out_range_high_rating_method);
   end;
   
   member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rec                 at_rating_spec%rowtype;
      l_office_code         number := cwms_util.get_office_code(self.office_id);
      l_template_code       number;
      l_base_location_code  number;
      l_location_code       number;
      l_parts               str_tab_t;
   begin
      begin
         l_template_code := self.get_template_code;
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating template',
               self.office_id||'/'||self.template_id);
      end;
      l_parts := cwms_util.split_text(l_template_code, ';');
      l_parts := cwms_util.split_text(l_parts(1), ',');
      if self.ind_rounding_specs is null then
         self.ind_rounding_specs := str_tab_t();
         self.ind_rounding_specs.extend(l_parts.count);
         for i in 1..l_parts.count loop
            self.ind_rounding_specs(i) := '0000000000';
         end loop;
      end if;
      if self.ind_rounding_specs.count != l_parts.count then
         cwms_err.raise(
            'ERROR',
            'Rating template id '''
            || self.office_id
            ||'/'
            || self.template_id
            || ''' has '
            || l_parts.count
            || ' independent parameters, but rating specification has '
            || self.ind_rounding_specs.count
            || ' rounding specifications'); 
      end if;
      begin
         l_location_code := self.get_location_code;
      exception
         when others then
            cwms_loc.create_location_raw(
               p_base_location_code => l_base_location_code, -- out, not used
               p_location_code      => l_location_code,      -- out
               p_base_location_id   => cwms_util.get_base_id(self.location_id),
               p_sub_location_id    => cwms_util.get_sub_id(self.location_id),
               p_db_office_code     => cwms_util.get_office_code(self.office_id));
      end;
      begin
         select *
           into l_rec
           from at_rating_spec
          where template_code = l_template_code
            and location_code = l_location_code
            and upper(version) = upper(self.version);
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Rating specification',
               self.office_id||'/'||self.location_id||'.'||self.template_id||'.'||self.version);
         end if;
         if source_agency_id is not null then
            l_rec.source_agency_code := self.get_source_agency_code;            
         end if;
         l_rec.in_range_rating_method       := self.get_in_range_rating_code;
         l_rec.out_range_low_rating_method  := self.get_out_range_low_rating_code;
         l_rec.out_range_high_rating_method := self.get_out_range_high_rating_code;
         l_rec.active_flag                  := self.active_flag;
         l_rec.auto_update_flag             := self.auto_update_flag;
         l_rec.auto_activate_flag           := self.auto_activate_flag;
         l_rec.auto_migrate_ext_flag        := self.auto_migrate_ext_flag;
         l_rec.dep_rounding_spec            := self.dep_rounding_spec;
         l_rec.description                  := self.description;
         
         update at_rating_spec
            set row = l_rec
          where rating_spec_code = l_rec.rating_spec_code;
          
         delete
           from at_rating_ind_rounding
          where rating_spec_code = l_rec.rating_spec_code;
                    
      exception
         when no_data_found then
            l_rec.rating_spec_code             := cwms_seq.nextval;
            l_rec.template_code                := l_template_code;
            l_rec.location_code                := l_location_code;
            l_rec.version                      := self.version;
            l_rec.in_range_rating_method       := self.get_in_range_rating_code;
            l_rec.out_range_low_rating_method  := self.get_out_range_low_rating_code;
            l_rec.out_range_high_rating_method := self.get_out_range_high_rating_code;
            l_rec.active_flag                  := self.active_flag;
            l_rec.auto_update_flag             := self.auto_update_flag;
            l_rec.auto_activate_flag           := self.auto_activate_flag;
            l_rec.auto_migrate_ext_flag        := self.auto_migrate_ext_flag;
            l_rec.dep_rounding_spec            := self.dep_rounding_spec;
            l_rec.description                  := self.description;
            
            insert
              into at_rating_spec
            values l_rec;
      end;
            
      for i in 1..self.ind_rounding_specs.count loop
         insert
           into at_rating_ind_rounding
         values (l_rec.rating_spec_code, i, self.ind_rounding_specs(i));
      end loop;   
   end;
   
   member function to_clob
   return clob
   is
      l_text clob;
      function bool_text(
         p_state in boolean)
      return varchar2
      is
      begin
         return case p_state
                   when true  then 'true'
                   when false then 'false'
                end;
      end;         
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating-spec office-id="'||self.office_id||'">'
         ||'<rating-spec-id>'||self.location_id||'.'||self.template_id||'.'||self.version||'</rating-spec-id>'
         ||'<template-id>'||self.template_id||'</template-id>'
         ||'<location-id>'||self.location_id||'</location-id>'
         ||'<version>'||self.location_id||'</version>'
         ||case self.source_agency_id is null
              when true  then '<source-agency/>'
              when false then '<source-agency>'||self.source_agency_id||'</source-agency>'
           end
         ||'<in-range-method>'||self.in_range_rating_method||'</in-range-method>'
         ||'<out-range-low-method>'||self.out_range_low_rating_method||'</out-range-low-method>'
         ||'<out-range-high-method>'||self.out_range_high_rating_method||'</out-range-high-method>'
         ||'<active>'||bool_text(cwms_util.is_true(self.active_flag))||'</active>'
         ||'<auto-update>'||bool_text(cwms_util.is_true(self.auto_update_flag))||'</auto-update>'
         ||'<auto-activate>'||bool_text(cwms_util.is_true(self.auto_activate_flag))||'</auto-activate>'
         ||'<auto-migrate-extension>'||bool_text(cwms_util.is_true(self.auto_migrate_ext_flag))||'</auto-migrate-extension>'
         ||'<ind-rounding-specs>');
      for i in 1..self.ind_rounding_specs.count loop
         cwms_util.append(l_text, '<ind-rounding-spec position="'||i||'">'||self.ind_rounding_specs(i)||'</ind-rounding-spec>');
      end loop;
      cwms_util.append(l_text, '</ind-rounding-specs>'
         ||'<dep-rounding-spec>'||self.dep_rounding_spec||'</dep-rounding-spec>'
         ||case self.description is null
              when true  then '<description/>'
              when false then '<description>'||self.description||'</description>'
           end
         ||'</rating-spec>');         
      dbms_lob.close(l_text);
      return l_text;
   end;     
   
   member function to_xml
   return xmltype
   is
   begin
      return xmltype(self.to_clob);
   end;
         
   static function get_rating_spec_code(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return number
   is
      l_office_id        varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
      l_office_code      number(10) := cwms_util.get_office_code(l_office_id);
      l_rating_spec_code number(10);
      l_parts            str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, '.');
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      
      select rating_spec_code
        into l_rating_spec_code
        from at_rating_spec
       where template_code = rating_template_t.get_template_code(p_template_id, l_office_code)
         and location_code = cwms_loc.get_location_code(l_office_id, p_location_id)
         and upper(version) = upper(p_version);
         
      return l_rating_spec_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Rating specification',
            l_office_id||'/'||p_location_id||'.'||p_template_id||'.'||p_version);
   end;      
         
   static function get_rating_spec_code(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return number
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_rating_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating specification');
      end if;
      return rating_spec_t.get_rating_spec_code( 
         l_parts(1),
         l_parts(2) || '.' || l_parts(3),
         l_parts(4),
         p_office_id);
   end;
end;
/
show errors;

create type rating_value_note_t as object(
   office_id   varchar2(16),
   note_id     varchar2(16),
   description varchar2(256),
   
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result,      
   
   member function get_note_code
   return number,
   
   member procedure store(
      p_fail_if_exists in varchar)
);
/
show errors;

create type body rating_value_note_t
as
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result
   is
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select *
              from at_rating_value_note
             where note_code = p_note_code
         )
      loop
         self.note_id     := rec.note_id;
         self.description := rec.description;
         
         select office_id
           into self.office_id
           from cwms_office
          where office_code = rec.office_code;
      end loop;
      return;         
  end;
            
   member function get_note_code
   return number
   is
      l_note_code number;
   begin
      select note_code
        into l_note_code
        from at_rating_value_note
       where office_code in (cwms_util.get_office_code(self.office_id), cwms_util.db_office_code_all)
         and note_id = upper(self.note_id);
         
      return l_note_code;         
   end;

   
   member procedure store(
      p_fail_if_exists in varchar)
   is
      l_rec           at_rating_value_note%rowtype;
      l_cwms_note_ids str_tab_t;
   begin
      if cwms_util.get_office_code(self.office_id) = cwms_util.db_office_code_all then
         cwms_err.raise(
            'ERROR',
            'Cannot store a rating value note for the CWMS office.');
      end if;
      select note_id bulk collect 
        into l_cwms_note_ids 
        from at_rating_value_note 
       where office_code = cwms_util.db_office_code_all;
      for i in 1..l_cwms_note_ids.count loop
         if upper(self.note_id) = l_cwms_note_ids(i) then
            cwms_err.raise(
               'ERROR',
               'NOTE_ID '|| upper(self.note_id) || ' exists for the CWMS office, cannot store.');
         end if;
      end loop; 
      l_rec.office_code := cwms_util.get_office_code(self.office_id);
      l_rec.note_id     := upper(self.note_id);
      begin
         select *
           into l_rec
           from at_rating_value_note
          where office_code = l_rec.office_code
            and note_id = l_rec.note_id;
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Rating value note',
               self.office_id || '/' || self.note_id);
        end if;
        l_rec.description := self.description;
        
        update at_rating_value_note
           set row = l_rec
         where note_code = l_rec.note_code;             
         
      exception
         when no_data_found then
            l_rec.description := self.description;
                    
            insert
              into at_rating_value_note
            values l_rec;             
      end;
   end;      

end;
/
show errors;

create type rating_value_note_tab_t is table of rating_value_note_t;
/
show errors;


create type abs_rating_ind_parameter_t as object(
   constructed varchar2(1)
) not final
  not instantiable;
/
show errors;

create type rating_value_t as object(
   ind_value            binary_double,
   dep_value            binary_double,
   dep_rating_ind_param abs_rating_ind_parameter_t,
   note_id              varchar2(16),
   
   constructor function rating_value_t
   return self as result,
   
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result,
   
   member procedure store(
      p_rating_ind_param_code in number,
      p_is_extension          in varchar2,
      p_office_id             in varchar2)
);
/
show errors;

create type rating_value_tab_t as table of rating_value_t;
/
show errors;

create type rating_ind_parameter_t under abs_rating_ind_parameter_t(
   rating_values      rating_value_tab_t,
   extension_values   rating_value_tab_t,
   
   constructor function rating_ind_parameter_t
   return self as result,
   
   constructor function rating_ind_parameter_t(
      p_rating_code in number)
   return self as result,
   
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result,
   
   member procedure init(
      p_rating_ind_parameter_code in number),
      
   member procedure validate_obj(
      p_parameter_position in number),
         
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2),
      
   member procedure store(
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2),
      
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   
   member function to_xml
   return xmltype,      
      
   static function get_rating_ind_parameter_code(
      p_rating_code in number)
   return number      
);
/
show errors;

create type body rating_ind_parameter_t
as
   constructor function rating_ind_parameter_t
   return self as result
   is
   begin
      -- members are null!
      return;
   end;

   constructor function rating_ind_parameter_t(
      p_rating_code in number)
   return self as result
   is
   begin
      init(rating_ind_parameter_t.get_rating_ind_parameter_code(p_rating_code));
      return;
   end;
   
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result
   is
      type rating_value_tab_by_id is table of rating_value_tab_t index by varchar2(32767);

      p_rating_ind_param     rating_ind_parameter_t := rating_ind_parameter_t();
      l_rating_points        xmltype;
      l_other_ind            xmltype;
      l_point                xmltype;
      l_note                 xmltype;
      l_position             number(1);
      l_value                binary_double;
      l_ind_value            binary_double;
      l_last_ind_value       binary_double;
      l_dep_value            binary_double;
      l_note_text            varchar2(64);
      l_rating_value         rating_value_t;
      l_rating_values        rating_value_tab_t;
      l_rating_ind_param     rating_ind_parameter_t;
      l_code                 number(10);
      l_value_at_pos         double_tab_t := double_tab_t();
      l_rating_value_tab_id  varchar2(32767);
      l_rating_value_tab     rating_value_tab_by_id;
      l_value_type           str_tab_t := str_tab_t('rating-points', 'extension-points');
      
      pragma autonomous_transaction; -- allows commit to flush temp table
      
      -------------------------------------------------------------------------
      -- local function to build rating by recursing through temporary table --
      -------------------------------------------------------------------------
      function build_rating(
         p_parent_id in varchar2,
         p_position  in integer default 1)
      return rating_value_tab_t
      is
         last_ind_value        at_compound_rating.ind_value%type;
         l_rating_param        rating_ind_parameter_t;
         l_rating              rating_value_tab_t := rating_value_tab_t();
         l_rating_value_tab_id varchar2(32767); -- hides outer declaration
      begin
         for rec in
            (  select ind_value
                 from at_compound_rating
                where position = p_position
                  and parent_id = p_parent_id
             order by seq
            )
         loop
            -------------------------------------------------------------
            -- manual filtering, can't use DISTINCT on temporary table --
            -------------------------------------------------------------
            if last_ind_value is null or rec.ind_value != last_ind_value then
               last_ind_value := rec.ind_value;
               --------------------------------------------------------------------------------
               -- create a new rating_value_t object at the end of the table and populate it --
               --------------------------------------------------------------------------------
               l_rating.extend;
               l_rating(l_rating.count) := rating_value_t();
               l_rating(l_rating.count).ind_value := rec.ind_value;
               -------------------------------------------------------------------------------- 
               -- create a temporary rating_ind_parameter_t object since the rating_values   --
               -- field is not addressable from the more abstract abs_rating_ind_parameter_t --
               -- field in l_rating(l_rating.count)                                          --
               -------------------------------------------------------------------------------- 
               l_rating_param := rating_ind_parameter_t();
               -------------------------------------------------------------------------
               -- build the index string to check for pre-built objects (also used as --
               -- p_parent_id parameter for the recursive call if necessary)          --
               -------------------------------------------------------------------------
               if p_position = 1 then
                  l_rating_value_tab_id := p_parent_id || rec.ind_value;
               else
                  l_rating_value_tab_id := p_parent_id || ',' || rec.ind_value;
               end if;
               if l_rating_value_tab.exists(l_rating_value_tab_id) then
                  -------------------------------------------------------
                  -- attach the pre-built rating_value_tab_t of values --
                  -------------------------------------------------------
                  l_rating_param.rating_values := l_rating_value_tab(l_rating_value_tab_id);
               else
                  --------------------------------------------------------------------------------------------
                  -- create a new rating_value_tab_t from info below the current position/value combination --
                  --------------------------------------------------------------------------------------------
                  l_rating_param.rating_values := build_rating(l_rating_value_tab_id, p_position+1);
               end if;
               -----------------------------------------------------------------------------------
               -- assign the newly-populated rating_ind_parameter_t to the dep_rating_ind_param --
               -- abs_rating_ind_parameter_t field of l_rating(l_rating.count)                  --
               -----------------------------------------------------------------------------------
               l_rating(l_rating.count).dep_rating_ind_param := l_rating_param;
            end if;         
         end loop;
         return l_rating;
      end;       
   begin
      for i in 1..l_value_type.count loop
         ----------------------------------------------------------------
         -- for each value type in 'rating-points', 'extension-points' --
         ----------------------------------------------------------------
         for j in 1..9999999 loop
            ------------------------------------------------------------
            -- for each <rating-points> or <extension-points> element --
            ------------------------------------------------------------
            l_rating_points       := p_xml.extract('/rating/'||l_value_type(i)||'['||j||']');
            exit when l_rating_points is null;
            l_position            := 0;
            l_rating_value_tab_id := l_value_type(i)||'=';
            for k in 1..9999999 loop
               ----------------------------------
               -- for each <other-ind> element --
               ----------------------------------
               l_other_ind := l_rating_points.extract('/'||l_value_type(i)||'/other-ind['||k||']');
               exit when l_other_ind is null;
               -----------------------------------------------
               -- extract the position and value attributes --
               -----------------------------------------------
               l_position := l_other_ind.extract('/other-ind/@position').getnumberval; 
               l_value    := l_other_ind.extract('/other-ind/@value').getnumberval;
               ---------------------------------------
               -- verify expected position sequence --
               ---------------------------------------
               if l_position != k then
                  cwms_err.raise(
                     'ERROR',
                     'Element '||k||' is out of sequential order: '||l_other_ind.getstringval);
               end if;
               if l_position > l_value_at_pos.count then
                  if j = 1 then
                     l_value_at_pos.extend;
                  else
                     cwms_err.raise(
                        'ERROR',
                        'All independent parameters must be introduced in first <'||l_value_type(i)||'> element,'
                        ||' found '
                        ||l_other_ind.getstringval
                        ||' in <'||l_value_type(i)||'> element '||j);
                  end if;
               end if;
               ---------------------------------------------------
               -- ensure values at this position are increasing --
               ---------------------------------------------------
               if l_value_at_pos(l_position) is not null and l_value < l_value_at_pos(l_position) then
                  cwms_err.raise(
                     'ERROR',
                     'Rating values '||l_rating_value_tab_id||': independent values do not monotonically increase');
               end if;
               ---------------------------------------------
               -- save the current value at this position --
               ---------------------------------------------
               l_value_at_pos(l_position) := l_value;
               for m in l_position+1..l_value_at_pos.count loop
                  l_value_at_pos(m) := null;
               end loop;
               ------------------------------------------------------------------------------ 
               -- save the info to a temporary table so it can be queried in another order --
               ------------------------------------------------------------------------------ 
               insert
                 into at_compound_rating
               values (1000000*i+1000*j+l_position, l_position, l_value_at_pos(l_position), l_rating_value_tab_id);
               --------------------------------------------------------------------------------
               -- update the rating value table id (used to query temporary table as well as --
               -- to index in-memory tables constructed from <point> elements below)         --
               --------------------------------------------------------------------------------
               if l_position > 1 then
                  l_rating_value_tab_id := l_rating_value_tab_id || ',' || l_value_at_pos(l_position);
               else
                  l_rating_value_tab_id := l_rating_value_tab_id || l_value_at_pos(l_position);
               end if;
            end loop;
            l_last_ind_value := null;
            l_rating_values  := rating_value_tab_t();
            for k in 1..9999999 loop
               ------------------------------
               -- for each <point> element --
               ------------------------------
               l_point := l_rating_points.extract('/'||l_value_type(i)||'/point['||k||']');
               exit when l_point is null;
               ------------------------------------------------------------------------------------
               -- extract the required <ind> and <dep> node values, and the optional <note> node --
               ------------------------------------------------------------------------------------
               l_ind_value := l_point.extract('/point/ind/node()').getnumberval;
               l_dep_value := l_point.extract('/point/dep/node()').getnumberval;
               l_note      := l_point.extract('/point/note');
               --------------------------------------------------
               -- ensure the independent values are increasing --
               --------------------------------------------------
               if l_last_ind_value is not null and l_ind_value <= l_last_ind_value then
                  cwms_err.raise(
                     'ERROR',
                     'Rating values '||l_rating_value_tab_id||': independent values do not monotonically increase');
               end if;
               ------------------------------------------------------------------------------------------------
               -- create and populate a new rating_value_t object at the end of the l_rating_values variable --
               ------------------------------------------------------------------------------------------------
               l_rating_value := rating_value_t();
               l_rating_value.ind_value := l_ind_value;
               l_rating_value.dep_value := l_dep_value;
               begin
                  l_rating_value.note_id := l_note.extract('/node()/text()').getstringval;
               exception
                  when others then if sqlcode = -30625 then null; else raise; end if;
               end;
               l_rating_values.extend;
               l_rating_values(l_rating_values.count) := l_rating_value;
            end loop;
            --------------------------------------------------------------------------------
            -- index the new rating_value_t by the rating value table id contructed above --
            --------------------------------------------------------------------------------
            l_rating_value_tab(l_rating_value_tab_id) := l_rating_values;
         end loop;
         -----------------------------------------------------------
         -- construct the rating_values or extension_values field --
         -----------------------------------------------------------
         l_rating_values := 
            case l_position = 0
               when true then 
                  case l_rating_value_tab.exists(l_rating_value_tab_id) -- only 1 input parameter
                     when true  then l_rating_value_tab(l_rating_value_tab_id)
                     when false then null
                  end
               when false then 
                  build_rating(l_value_type(i)||'=') 
            end;
         case i
            when 1 then self.rating_values    := l_rating_values;
            when 2 then self.extension_values := l_rating_values;
         end case;
      end loop;
      commit; -- flush temporary table
      validate_obj(1);
      return;
   end;
   
   member procedure init(
      p_rating_ind_parameter_code in number)
   is
      l_parameter_position number(1);
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select *
              from at_rating_ind_parameter
             where rating_ind_param_code = p_rating_ind_parameter_code 
         )
      loop
         self.rating_values := rating_value_tab_t();
         for rec2 in
            (  select ind_value
                 from at_rating_value
                where rating_ind_param_code = rec.rating_ind_param_code
             order by ind_value
            )
         loop
            self.rating_values.extend;
            self.rating_values(self.rating_values.count) := rating_value_t(
                  rec.rating_ind_param_code, 
                  rec2.ind_value,
                  'F');
         end loop;
         
         self.extension_values := rating_value_tab_t();
         for rec2 in
            (  select ind_value
                 from at_rating_extension_value
                where rating_ind_param_code = rec.rating_ind_param_code
             order by ind_value
            )
         loop
            self.extension_values.extend;
            self.extension_values(self.extension_values.count) := rating_value_t(
                  rec.rating_ind_param_code, 
                  rec2.ind_value,
                  'T');
         end loop;
         if self.extension_values.count = 0 then
            self.extension_values := null;
         end if;
      end loop;
      select parameter_position
        into l_parameter_position
        from at_rating_ind_param_spec rips,
             at_rating_ind_parameter rip
       where rip.rating_ind_param_code = p_rating_ind_parameter_code
         and rips.ind_param_spec_code = rip.ind_param_spec_code;
      self.validate_obj(l_parameter_position);
      self.constructed := 'T';
   end;
      
   member procedure validate_obj(
      p_parameter_position in number)
   is
      l_deepest boolean;
   begin
      -------------------------
      -- rating values table --
      -------------------------
      if self.rating_values is null or self.rating_values.count = 0 then
         cwms_err.raise(
            'ERROR',
            'Rating independent parameter '||p_parameter_position||' has no values');
      else
         for i in 1..self.rating_values.count loop
            if l_deepest is null then
               l_deepest := self.rating_values(i).dep_rating_ind_param is null; 
            else
               if(self.rating_values(i).dep_rating_ind_param is null) != l_deepest then
                  cwms_err.raise(
                     'ERROR',
                     'Rating parameter position '||p_parameter_position||' contains both values and ratings');
               end if; 
            end if;
            -------------------------------
            -- dependent value/reference --
            -------------------------------
            if self.rating_values(i).dep_value is not null and
               self.rating_values(i).dep_rating_ind_param is not null
            then
               cwms_err.raise(
                  'ERROR',
                  'Rating independent parameter '
                  ||p_parameter_position
                  ||' rating value cannot have both a dependent value and a dependent sub-rating');
            end if; 
            if self.rating_values(i).dep_value is null then
               if self.rating_values(i).dep_rating_ind_param is null then
                  cwms_err.raise(
                     'ERROR',
                     'Rating independent parameter '
                     ||p_parameter_position
                     ||' rating value must have either a dependent value or a dependent sub-rating');
               elsif self.rating_values(i).note_id is not null then
                  cwms_err.raise(
                     'ERROR',
                     'Rating value notes can only be assigned to dependent values');
               end if;
            end if; 
            ------------------------
            -- independent values --
            ------------------------
            if self.rating_values(i).ind_value is null or 
               (i > 1 and self.rating_values(i).ind_value <= self.rating_values(i-1).ind_value)
            then
               cwms_err.raise(
                  'ERROR',
                  'Rating independent parameter '
                  ||p_parameter_position
                  ||' rating values do not monotonically increase');
            end if; 
         end loop;
      end if;
      ----------------------------
      -- extension values table --
      ----------------------------
      l_deepest := null;
      if self.extension_values is not null then
         for i in 1..self.extension_values.count loop
            if l_deepest is null then
               l_deepest := self.extension_values(i).dep_rating_ind_param is null; 
            else
               if(self.extension_values(i).dep_rating_ind_param is null) != l_deepest then
                  cwms_err.raise(
                     'ERROR',
                     'Extension parameter position '||p_parameter_position||' contains both values and ratings');
               end if; 
            end if;
            -------------------------------
            -- dependent value/reference --
            -------------------------------
            if self.extension_values(i).dep_value is not null and
               self.extension_values(i).dep_rating_ind_param is not null
            then
               cwms_err.raise(
                  'ERROR',
                  'Rating independent parameter '
                  ||p_parameter_position
                  ||' extension value cannot have both a dependent value and a dependent sub-rating');
            end if; 
            if self.extension_values(i).dep_value is null then
               if self.extension_values(i).dep_rating_ind_param is null then
                  cwms_err.raise(
                     'ERROR',
                     'Rating independent parameter '
                     ||p_parameter_position
                     ||' extension value must have either a dependent value or a dependent sub-rating');
               elsif self.extension_values(i).note_id is not null then
                  cwms_err.raise(
                     'ERROR',
                     'Rating value notes can only be assigned to dependent values');
               end if;
            end if; 
            ------------------------
            -- independent values --
            ------------------------
            if self.extension_values(i).ind_value is null or 
               (i > 1 and self.extension_values(i).ind_value <= self.extension_values(i-1).ind_value)
            then
               cwms_err.raise(
                  'ERROR',
                  'Rating independent parameter '
                  ||p_parameter_position
                  ||' extension values do not monotonically increase');
            end if; 
         end loop;
      end if;
   end;
   
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2)
   is
      l_rec       at_rating_ind_parameter%rowtype;
      l_office_id varchar2(16);
      l_value     rating_value_t;
   begin
      l_rec.rating_code := p_rating_code;
      
      begin
         select rips.ind_param_spec_code
           into l_rec.ind_param_spec_code
           from at_rating r,
                at_rating_spec rs,
                at_rating_ind_param_spec rips
          where r.rating_code = p_rating_code
            and rs.rating_spec_code = r.rating_spec_code
            and rips.template_code = rs.template_code
            and rips.parameter_position = p_parameter_position; 
      exception
         when no_data_found then
            cwms_err.raise(
               'ERROR',
               'Invalid parameter position: '||p_parameter_position);
      end;
      
      begin
         select *
           into l_rec
           from at_rating_ind_parameter
          where rating_code = l_rec.rating_code
            and ind_param_spec_code = l_rec.ind_param_spec_code;
            
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Rating independent parameter',
               l_rec.rating_ind_param_code);
         end if;         
         
         delete
           from at_rating_value
          where rating_ind_param_code = l_rec.rating_ind_param_code;
         
         delete
           from at_rating_extension_value
          where rating_ind_param_code = l_rec.rating_ind_param_code;
      exception
         when no_data_found then
            l_rec.rating_ind_param_code := cwms_seq.nextval;
            insert 
              into at_rating_ind_parameter
            values l_rec;
      end;            
      
      select co.office_id
        into l_office_id
        from at_rating r,
             at_rating_spec rs,
             at_rating_template rt,
             cwms_office co
       where r.rating_code = p_rating_code
         and rs.rating_spec_code = r.rating_spec_code
         and rt.template_code = rs.template_code
         and co.office_code = rt.office_code;    
      
      for i in 1..self.rating_values.count loop
         l_value := self.rating_values(i); 
         l_value.store(
            p_rating_ind_param_code => l_rec.rating_ind_param_code, 
            p_is_extension          => 'F',
            p_office_id             => l_office_id);
      end loop;       
          
      if self.extension_values is not null then
         for i in 1..self.extension_values.count loop
            l_value := self.extension_values(i);
            l_value.store(
               p_rating_ind_param_code => l_rec.rating_ind_param_code, 
               p_is_extension          => 'T',
               p_office_id             => l_office_id);
         end loop;       
      end if;
      
      p_rating_ind_param_code := l_rec.rating_ind_param_code;      
   end;      
   
   member procedure store(
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2)
   is
      l_rating_ind_param_code number(10);
   begin
      self.store(
         l_rating_ind_param_code,
         p_rating_code,
         p_parameter_position,
         p_fail_if_exists);
   end;
      
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob
   is
      l_text       clob;
      l_dep_rating rating_ind_parameter_t;
      l_deepest    boolean;
      l_ind_params double_tab_t := p_ind_params;
      l_position   simple_integer := 0;
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      if l_ind_params is null then
         l_ind_params := double_tab_t();
      end if;
      l_position := l_ind_params.count + 1;
      for i in 1..self.rating_values.count loop
         if l_deepest is null then
            l_deepest := self.rating_values(i).dep_rating_ind_param is null; 
         else
            if(self.rating_values(i).dep_rating_ind_param is null) != l_deepest then
               cwms_err.raise(
                  'ERROR',
                  'Rating parameter position '||l_position||' contains both values and ratings');
            end if; 
         end if;
         if self.rating_values(i).dep_value is null then
            ----------------------------
            -- recurse down one level --
            ----------------------------
            l_dep_rating := treat(
               self.rating_values(i).dep_rating_ind_param as rating_ind_parameter_t);
            l_ind_params.extend;
            l_ind_params(l_ind_params.count) := self.rating_values(i).ind_value;    
            cwms_util.append(l_text, l_dep_rating.to_clob(l_ind_params, p_is_extension));  
            l_ind_params.trim(1);
         else
            if i = 1 then
               ----------------------------
               -- output the opening tag --
               ----------------------------
               cwms_util.append(
                  l_text, 
                  case p_is_extension
                     when true  then '<extension-points>'
                     when false then '<rating-points>'
                  end);
               ---------------------------------------------------
               -- output any other independent parameter values --
               ---------------------------------------------------
               for j in 1..l_ind_params.count loop
                  cwms_util.append(l_text, '<other-ind position="'
                     ||j
                     ||'" value="'  
                     ||l_ind_params(j)  
                     ||'"/>');
               end loop;   
            end if;
            --------------------------------
            -- output the <point> element --
            --------------------------------
            cwms_util.append(l_text, '<point><ind>'
               ||self.rating_values(i).ind_value
               ||'</ind><dep>'
               ||self.rating_values(i).dep_value
               ||'</dep>'
               ||case self.rating_values(i).note_id is not null
                    when true then '<note>'||self.rating_values(i).note_id||'</note>'
                 end
               ||'</point>');
         end if;
      end loop;
      if l_deepest then
         ----------------------------
         -- output the closing tag --
         ----------------------------
         cwms_util.append(
            l_text, 
            case p_is_extension
               when true  then '</extension-points>'
               when false then '</rating-points>'
            end);
      end if;
      dbms_lob.close(l_text);
      return l_text;
   end;
   
   member function to_xml
   return xmltype
   is
      l_text clob;
      l_code number;
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating-ind-parameter>'); -- element for testing only
      cwms_util.append(l_text, self.to_clob);
      cwms_util.append(l_text, '</rating-ind-parameter>');
      dbms_lob.close(l_text);
      return xmltype(l_text);
   end;      
      
   static function get_rating_ind_parameter_code(
      p_rating_code in number)
   return number
   is
      l_rating_in_parameter_code number(10);
   begin
      -------------------------------------------------------------
      -- we should have only a single record with combination of --
      -- input rating code and ind_param_spec_code wiht pos = 1  --
      -------------------------------------------------------------
      select rip.rating_ind_param_code
        into l_rating_in_parameter_code
        from at_rating_ind_parameter rip,
             at_rating r,
             at_rating_spec rs,
             at_rating_ind_param_spec rips
       where r.rating_code = p_rating_code
         and rs.rating_spec_code = r.rating_spec_code
         and rips.template_code = rs.template_code
         and rips.parameter_position = 1 
         and rip.rating_code = r.rating_code
         and rip.ind_param_spec_code = rips.ind_param_spec_code;
         
      return l_rating_in_parameter_code;
   end;
         
end;
/
show errors;

create type rating_ind_parameter_tab_t as table of rating_ind_parameter_t;
/
show errors;

create type body rating_value_t
as
   
   constructor function rating_value_t
   return self as result
   is
   begin
      -- members are null!
      return;
   end;
   
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result
   is
      l_rec        at_rating_value%rowtype;
      l_table_name varchar2(30);
   begin
      l_table_name :=
         case cwms_util.is_true(p_is_extension)
            when true  then 'at_rating_extension_value'
            when false then 'at_rating_value'
         end;
      execute immediate         
         'select *
           from :table_name
          where rating_ind_param_code = p_rating_ind_param_code
            and ind_value = p_ind_value'
      into l_rec            
      using l_table_name;
      
      self.ind_value := l_rec.ind_value;
      self.dep_value := l_rec.dep_value;
      
      if l_rec.dep_rating_ind_param_code is not null then
         self.dep_rating_ind_param := rating_ind_parameter_t(l_rec.dep_rating_ind_param_code);
      end if;
      
      if l_rec.note_code is not null then
         select note_id
           into self.note_id
           from at_rating_value_note
          where note_code = l_rec.note_code;
      end if;              
   end;
   
   member procedure store(
      p_rating_ind_param_code in number,
      p_is_extension          in varchar2,
      p_office_id             in varchar2)
   is
      l_rec                  at_rating_value%rowtype;
      l_note_rec             at_rating_value_note%rowtype;
      l_office_code          number(10) := cwms_util.get_office_code(p_office_id);
      l_rating_code          number(10);
      l_rating_ind_parameter rating_ind_parameter_t;
      l_parameter_position   number(1);
   begin
      if self.note_id is not null then
         begin
            select *
              into l_note_rec
              from at_rating_value_note
             where office_code in (l_office_code, cwms_util.db_office_code_all)
               and upper(note_id) = upper(self.note_id);
         exception
            when no_data_found then
               l_note_rec.note_code   := cwms_seq.nextval;
               l_note_rec.office_code := l_office_code;
               l_note_rec.note_id     := self.note_id;
               
               insert
                 into at_rating_value_note
               values l_note_rec;
         end;
      end if;
      if self.dep_rating_ind_param is not null then
         select rips.parameter_position
           into l_parameter_position
           from at_rating_ind_parameter rip,
                at_rating_ind_param_spec rips
          where rips.ind_param_spec_code = rip.ind_param_spec_code;
          
         select rating_code
           into l_rating_code
           from at_rating_ind_parameter
          where rating_ind_param_code = p_rating_ind_param_code;
           
         l_rating_ind_parameter := treat(self.dep_rating_ind_param as rating_ind_parameter_t);
         l_rating_ind_parameter.store(
            p_rating_ind_param_code => l_rec.dep_rating_ind_param_code,
            p_rating_code           => l_rating_code,
            p_parameter_position    => l_parameter_position + 1,
            p_fail_if_exists        => 'F');
      end if;
      l_rec.rating_ind_param_code := p_rating_ind_param_code;
      l_rec.ind_value := self.ind_value;
      l_rec.dep_value := self.dep_value;
      l_rec.note_code := l_note_rec.note_code;               
      
      if cwms_util.is_true(p_is_extension) then
         insert
           into at_rating_extension_value
         values l_rec;
      else
         insert
           into at_rating_value
         values l_rec;
      end if;
   end;      
end;
/
show errors;

create type rating_t as object(
   office_id      varchar2(16),
   rating_spec_id varchar2(372),
   effective_date date,
   create_date    date,
   active_flag    varchar2(1),
   formula        varchar2(1000),
   native_units   varchar2(256),
   description    varchar2(256),
   rating_info    rating_ind_parameter_t,
   
   constructor function rating_t(
      p_rating_code in number)
   return self as result,
   
   constructor function rating_t(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
      
   constructor function rating_t(
      p_xml in xmltype)
   return self as result,
   
   member procedure init(
      p_rating_code in number),
   
   member procedure init(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null),
      
   member procedure validate_obj,
         
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2),
   
   member procedure store(
      p_fail_if_exists in varchar2),
      
   member function to_clob
   return clob,
   
   member function to_xml
   return xmltype,      
      
   static function get_rating_code(         
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return number      
      
) not final;
/
show errors;

create type body rating_t
as
   constructor function rating_t(
      p_rating_code in number)
   return self as result
   is
   begin
      init(p_rating_code);
      return;
   end;
   
   constructor function rating_t(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result
   is
   begin
      init(
         p_rating_spec_id,
         p_effective_date,
         p_match_date,
         p_time_zone,
         p_office_id);
         
      return;
   end;
      
   constructor function rating_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml     xmltype;
      l_node    xmltype;
      l_timestr varchar2(32);
      
      -------------------------------------------------------------------
      -- local function to retrieve xml dateTime value into local date --
      -------------------------------------------------------------------
      function get_date(p_timestr in varchar2) return date
      is
         l_date     date;
         l_timezone varchar2(28);
         l_parts    str_tab_t;
         l_timestr  varchar2(32); -- hides outer declaration
      begin
         l_date := cwms_util.to_timestamp(substr(p_timestr, 1, 19));
         l_timestr := substr(p_timestr, 20);
         if l_timestr is null then
            ----------------------------
            -- assume local time zone --
            ----------------------------
            null;
         else
            ------------------------------
            -- shift to local time zone --
            ------------------------------
            l_timestr := 'Etc/GMT'
            ||case substr(l_timestr, 1, 1)
                 when '+' then '-' || to_number(l_timestr, 2, 2) 
                 when '-' then '+' || to_number(l_timestr, 2, 2)
              end;
            l_parts := cwms_util.split_text(self.rating_spec_id, '.');              
            select tz.time_zone_name
              into l_timezone
              from at_base_location bl,
                   at_physical_location pl,
                   cwms_office o,
                   cwms_time_zone tz
             where o.office_id = upper(self.office_id)
                   and bl.db_office_code = o.office_code
                   and bl.base_location_id = cwms_util.get_base_id(l_parts(1))
                   and nvl(pl.sub_location_id, '.') = nvl(cwms_util.get_sub_id(l_parts(1)), '.') 
                   and tz.time_zone_code = nvl(pl.time_zone_code, 0);
            if l_timezone = 'Unknown or Not Applicable' then
               l_timezone := 'UTC';
            end if;
            l_date := cwms_util.change_timezone(l_date, l_timestr, l_timezone);
         end if;
         return l_date;
      end;      
   begin
      if p_xml.existsnode('//rating[1]') = 1 then
         l_xml := p_xml.extract('//rating[1]');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating> element');
      end if;
      if l_xml.existsnode('/rating/@office-id') = 1 then
         self.office_id := l_xml.extract('/rating/@office-id').getstringval;
      else
         cwms_err.raise('ERROR', 'Required office-id attribute not found');
      end if;
      if l_xml.existsnode('/rating/rating-spec-id') = 1 then
         self.rating_spec_id := l_xml.extract('/rating/rating-spec-id/node()').getstringval;
      else
         cwms_err.raise('ERROR', 'Required <rating-spec-id> element not found');
      end if;
      if l_xml.existsnode('/rating/effective-date') = 1 then
         l_timestr := l_xml.extract('/rating/effective-date/node()').getstringval;
         self.effective_date := get_date(l_timestr);
      else
         cwms_err.raise('ERROR', 'Required <effective-date> element not found');
      end if;
      if l_xml.existsnode('/rating/create-date') = 1 then
         l_node := l_xml.extract('/rating/create-date/node()');
         if l_node is not null then
            l_timestr := l_node.getstringval;
            self.create_date := get_date(l_timestr);
         end if;
      end if;
      if l_xml.existsnode('/rating/active') = 1 then
         self.active_flag := 
            case l_xml.extract('/rating/active/node()').getstringval
               when 'true'  then 'T'
               when 'false' then 'F'
            end;
         if self.active_flag is null then
            cwms_err.raise(
               'ERROR', 
               'Invalid text for <active> element: '
               ||l_xml.extract('/rating/active/node()').getstringval);
         end if;            
      else
         cwms_err.raise('ERROR', 'Required <active> element not found');
      end if;
      if l_xml.existsnode('/rating/formula') = 1 then
         l_node := l_xml.extract('/rating/formula/node()');
         if l_node is not null then
            self.formula := l_node.getstringval;
         end if;
      end if;
      if l_xml.existsnode('/rating/units-id') = 1 then
         self.native_units := l_xml.extract('/rating/units-id/node()').getstringval;
      else
         cwms_err.raise('ERROR', 'Required <units-id> element not found');
      end if;
      if l_xml.existsnode('/rating/description') = 1 then
         l_node := l_xml.extract('/rating/description/node()');
         if l_node is not null then
            self.description := l_node.getstringval;
         end if;
      end if;
      self.rating_info := rating_ind_parameter_t(l_xml);
      self.validate_obj;
      return;
   end;
      
   member procedure init(
      p_rating_code in number)
   is
      l_time_zone            varchar2(28);
      l_ind_param_count      number(1);
      l_ind_param_spec_codes number_tab_t := number_tab_t();
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select *
              from at_rating
             where rating_code = p_rating_code
         )
      loop
         for rec2 in
            (
               select template_code,
                      location_code,
                      version
                 from at_rating_spec
                where rating_spec_code = rec.rating_spec_code
            )
         loop
            for rec3 in 
               (  select template_code,
                         office_code,
                         parameters_id,
                         version
                    from at_rating_template
                   where template_code = rec2.template_code
               )
            loop
               select office_id
                 into self.office_id
                 from cwms_office
                where office_code = rec3.office_code;
                
               self.rating_spec_id := 
                  cwms_util.get_location_id(rec2.location_code, 'F')
                  ||'.'
                  ||rec3.parameters_id
                  ||'.'
                  ||rec3.version
                  ||'.'
                  ||rec2.version;
                  
               l_ind_param_count := cwms_util.split_text(rec3.parameters_id, ',').count;
               
               select ind_param_spec_code bulk collect
                 into l_ind_param_spec_codes
                 from at_rating_ind_param_spec
                where template_code = rec3.template_code
             order by parameter_position;

               if l_ind_param_spec_codes.count != l_ind_param_count then
                  cwms_err.raise(
                     'ERROR',
                     'Rating template has '
                     ||l_ind_param_spec_codes.count
                     ||' independent parameter(s), but rating has '
                     ||l_ind_param_count);
               end if;                         
            end loop;
            select tz.time_zone_name
              into l_time_zone
              from at_physical_location pl,
                   cwms_time_zone tz
             where pl.location_code = rec2.location_code
               and tz.time_zone_code = nvl(pl.time_zone_code, 0);
            if l_time_zone = 'Unknown or Not Applicable' then
               l_time_zone := 'UTC';
            end if;
         end loop;
         self.effective_date := cwms_util.change_timezone(rec.effective_date, 'UTC', l_time_zone);               
         self.create_date    := cwms_util.change_timezone(rec.create_date, 'UTC', l_time_zone);
         self.active_flag    := rec.active_flag;
         self.formula        := rec.formula;
         self.native_units   := rec.native_units;
         self.description    := rec.description;
         self.rating_info    := rating_ind_parameter_t(p_rating_code);
      end loop;
      validate_obj;
   end;      
   
   member procedure init(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   is
      l_rating_code number(10);
   begin
      l_rating_code := rating_t.get_rating_code(
         p_rating_spec_id,
         p_effective_date,
         p_match_date,
         p_time_zone,
         p_office_id);
         
      init(l_rating_code);
   end;      
      
   member procedure validate_obj
   is
      l_code   number(10);
      l_parts  str_tab_t;
      l_params str_tab_t;
      l_units  str_tab_t;
      l_factor binary_double;
      l_offset binary_double;
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
      --------------------
      -- rating spec... --
      --------------------
      if self.rating_spec_id is null then
         cwms_err.raise(
            'ERROR',
            'Rating specification identifier not found');
      end if;
      l_parts := cwms_util.split_text(self.rating_spec_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            self.rating_spec_id,
            'Rating specification identifier');
      end if;
      -----------------
      -- ...location --
      -----------------
      l_code := cwms_loc.get_location_code(self.office_id, l_parts(1));
      -------------------------
      -- ...template version --
      -------------------------
      if l_parts(3) is null then
         cwms_err.raise(
            'ERROR',
            'Rating specification identifier contains NULL template version');
      end if;
      ----------------
      -- ...version --
      ----------------
      if l_parts(4) is null then
         cwms_err.raise(
            'ERROR',
            'Rating specification identifier contains NULL version');
      end if;
      -------------------
      -- ...parameters --
      -------------------
      l_parts := cwms_util.split_text(l_parts(2), ';');
      if l_parts.count != 2 then
         cwms_err.raise(
            'ERROR',
            'Rating specification identifier contains invalid template parameters identifier');
      end if;
      l_params := cwms_util.split_text(l_parts(1), ',');
      for i in 1..l_params.count loop
         begin
            select base_parameter_code
              into l_code
              from cwms_base_parameter
             where base_parameter_id = cwms_util.get_base_id(l_params(i));
         exception
            when no_data_found then
               cwms_err.raise(
                  'ERROR',
                  'Rating specification identifier contains invalid base parameter: '||l_params(i));
         end;
      end loop;
      begin
         select base_parameter_code
           into l_code
           from cwms_base_parameter
          where base_parameter_id = cwms_util.get_base_id(l_parts(2));
      exception
         when no_data_found then
            cwms_err.raise(
               'ERROR',
               'Rating specification identifier contains invalid base parameter: '||l_parts(2));
      end;
      l_params.extend;
      l_params(l_params.count) := l_parts(2);
      ------------------
      -- native units --
      ------------------
      if self.native_units is not null then
         l_parts := cwms_util.split_text(self.native_units, ';');
         if l_parts.count != 2 then
            cwms_err.raise(
               'INVALID_ITEM',
               self.rating_spec_id,
               'Rating native units identifier');
         end if;
         l_units := cwms_util.split_text(l_parts(1), ',');
         if l_units.count != l_params.count - 1 then
            cwms_err.raise(
               'ERROR',
               'Native units specification indicates '
               ||l_units.count
               ||' independent parameters, rating specification contains '
               ||l_params.count - 1
               ||' independent parameters');
         end if;
         l_units.extend;
         l_units(l_units.count) := l_parts(2);
         for i in 1..l_units.count loop
            begin
               select unit_code
                 into l_code
                 from cwms_unit
                where unit_id = l_units(i);
            exception
               when no_data_found then
                  cwms_err.raise(
                     'ERROR',
                     'Native units specification contains invalid unit: '||l_units(i));
            end;
            begin
               select factor,
                      offset
                 into l_factor,
                      l_offset
                 from cwms_unit_conversion
                where to_unit_id = cwms_util.get_default_units(l_params(i), 'SI')
                  and from_unit_id = l_units(i);
            exception
               when no_data_found then
                  cwms_err.raise(
                     'ERROR',
                     'Native unit "'||l_units(i)||'" is invalid for parameter "'||l_params(i)||'"');
            end;
         end loop;       
      end if;
      ----------------------
      -- formula / points --
      ----------------------
      if self.formula is null then
         if self.rating_info is null then
            cwms_err.raise(
               'ERROR',
               'Either formula or rating points must be specified');
         else
            ------------------------------------------
            -- ind_params validated on construction --
            ------------------------------------------
            null;
         end if;
      else
         if self.rating_info is null then
            -------------
            -- formula --
            -------------
            declare
               l_tokens   str_tab_t;
               l_count    number_tab_t;
               l_position integer;
            begin
               if instr(self.formula, '(') > 0 then
                  l_tokens := cwms_util.tokenize_algebraic(self.formula);
               else
                  l_tokens := cwms_util.tokenize_rpn(self.formula);
                  if l_tokens.count > 1 and
                     l_tokens(l_tokens.count) not in
                     ('+','-','*','/','//','%','^','ABS','ACOS','ASIN','ATAN','CEIL',
                      'COS','EXP','FLOOR','LN','LOG', 'SIGN','SIN','TAN','TRUNC')
                  then
                     l_tokens := cwms_util.tokenize_algebraic(self.formula);
                  end if;            
               end if;
               l_count := number_tab_t();
               l_count.extend(l_params.count - 1);
               for i in 1..l_count.count loop
                  l_count(i) := 0;
               end loop;
               for i in 1..l_tokens.count loop
                  if upper(l_tokens(i)) = 'ARG' then
                     begin
                        l_position := to_number(substr(l_tokens(i), 4));
                        l_count(l_position) := l_count(l_position) + 1;  
                     exception
                        when others then
                           if sqlcode = -6502 then
                              cwms_err.raise(
                                 'ERROR',
                                 'Formula contains invalid token: '||l_tokens(i));
                           else
                              raise;
                           end if;
                     end;
                  end if;
               end loop;
               for i in 1..l_count.count loop
                  if l_count(i) = 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Formula does not contain token ARG'||i);
                  end if;
               end loop;
            end;
         else
            cwms_err.raise(
               'ERROR',
               'Formula and rating points cannot both be specified');
         end if;
      end if;
   end;
   
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2)
   is
      l_rec       at_rating%rowtype;
      l_time_zone varchar2(28);
      l_exists    boolean := true;
   begin
      l_rec.rating_spec_code := rating_spec_t.get_rating_spec_code(
         self.rating_spec_id,
         self.office_id);
         
      select tz.time_zone_name
        into l_time_zone
        from at_rating_spec rs,
             at_physical_location pl,
             cwms_time_zone tz
       where rs.rating_spec_code = l_rec.rating_spec_code
         and pl.location_code = rs.location_code
         and tz.time_zone_code = nvl(pl.time_zone_code, 0);
         
      if l_time_zone = 'Unknown or Not Applicable' then
         l_time_zone := 'UTC';
      end if;
      
      l_rec.effective_date := cwms_util.change_timezone(self.effective_date, l_time_zone, 'UTC');
      
      begin
         select *
           into l_rec
           from at_rating
          where rating_spec_code = l_rec.rating_spec_code
            and effective_date = l_rec.effective_date;
            
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Rating',
               self.office_id
               ||'/'
               ||self.rating_spec_id
               ||' - '
               ||to_char(self.effective_date, 'yyyy/mm/dd hh24mi')
               ||' ('
               ||l_time_zone
               ||')');
         end if;
      exception
         when no_data_found then
            l_exists := false;
            l_rec.rating_code := cwms_seq.nextval;
      end;

      l_rec.ref_rating_code := null;
      l_rec.create_date     := cwms_util.change_timezone(self.create_date, l_time_zone, 'UTC');
      l_rec.active_flag     := self.active_flag;
      l_rec.formula         := self.formula;
      l_rec.native_units    := self.native_units;
      l_rec.description     := self.description;
      
      if l_exists then
         update at_rating
            set row = l_rec
          where rating_code = l_rec.rating_code;
      else
         insert
           into at_rating
         values l_rec;
      end if;
      
      if self.rating_info is not null then
         self.rating_info.store(l_rec.rating_code, 1, 'F');
      end if;
      
      p_rating_code := l_rec.rating_code;
   end;
   
   member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rating_code number(10);
   begin
      self.store(l_rating_code, p_fail_if_exists);
   end;
      
   member function to_clob
   return clob
   is
      l_text           clob;
      l_parts          str_tab_t;
      l_time_zone      varchar2(28);
      l_effective_date date;
      l_create_date    date;
      function bool_text(
         p_state in boolean)
      return varchar2
      is
      begin
         return case p_state
                   when true  then 'true'
                   when false then 'false'
                end;
      end;         
   begin
      l_parts := cwms_util.split_text(self.rating_spec_id, '.');
      select tz.time_zone_name
        into l_time_zone
        from at_physical_location pl,
             cwms_time_zone tz
       where pl.location_code = cwms_loc.get_location_code(self.office_id, l_parts(1))
         and tz.time_zone_code = nvl(pl.time_zone_code, 0);
      if l_time_zone = 'Unknown or Not Applicable' then
         l_time_zone := 'UTC';
      end if;
      l_effective_date := cwms_util.change_timezone(self.effective_date, 'UTC', l_time_zone);
      l_create_date    := cwms_util.change_timezone(self.create_date, 'UTC', l_time_zone);
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating office-id="'||self.office_id||'">'
         ||'<rating-spec-id>'||self.rating_spec_id||'</rating-spec-id>'
         ||'<units-id>'||self.native_units||'</units-id>'
         ||'<effective-date>'||to_char(l_effective_date, 'yyyy-mm-dd"T"hh24:mi:ss')||'</effective-date>');
      if l_create_date is not null then
         cwms_util.append(l_text, '<create-date>'||to_char(l_create_date, 'yyyy-mm-dd"T"hh24:mi:ss')||'</create-date>'); 
      end if;            
      cwms_util.append(l_text,'<active>'||bool_text(cwms_util.is_true(self.active_flag))||'</active>'
         ||case self.description is null
              when true  then '<description/>'
              when false then '<description>'||self.description||'</description>'
           end);
      if self.formula is null then
         cwms_util.append(l_text, self.rating_info.to_clob);
      else
         cwms_util.append(l_text, '<formula>'||self.formula||'</formula>');           
      end if;
      cwms_util.append(l_text, '</rating>');   
      dbms_lob.close(l_text);
      return l_text;
   end;
   
   member function to_xml
   return xmltype
   is
   begin
      return xmltype(self.to_clob);
   end;      
      
   static function get_rating_code(         
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return number
   is
      l_parts                   str_tab_t;
      l_location_id             varchar2(49);
      l_template_parameters_id  varchar2(256);
      l_template_version        varchar2(32);
      l_version                 varchar2(32);
      l_office_id               varchar2(16);
      l_office_code             number;
      l_rating_spec_code        number;
      l_effective_date          date;
      l_time_zone               varchar2(28);
      l_rating_code             number;
   begin
      l_office_id := nvl(p_office_id, cwms_util.user_office_id);
      l_office_code := cwms_util.get_office_code(l_office_id);
      l_parts := cwms_util.split_text(p_rating_spec_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_spec_id,
            'Rating identifier');
      end if;
      l_location_id            := l_parts(1);
      l_template_parameters_id := l_parts(2);
      l_template_version       := l_parts(3);
      l_version                := l_parts(4);
      
      begin
         select ls.rating_spec_code
           into l_rating_spec_code
           from at_rating_spec ls,
                at_rating_template lt
          where lt.office_code = l_office_code
            and upper(lt.parameters_id) = upper(l_template_parameters_id)
            and upper(lt.version) = upper(l_template_version)
            and ls.template_code = lt.template_code
            and ls.location_code = cwms_loc.get_location_code(l_office_code, l_location_id)
            and upper(ls.version) = upper(l_version);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating specification',
               l_office_id||'/'||p_rating_spec_id);
      end;
      
      if p_effective_date is null then
         if cwms_util.is_true(p_match_date) then
            cwms_err.raise(
               'ERROR',
               'Cannot specify p_match_date => ''T'' with p_effecive_date => null');
         end if;
         l_effective_date := sysdate;
         l_time_zone := 'UTC';
      else
         if p_time_zone is null then
            select tz.time_zone_name
              into l_time_zone
              from at_physical_location pl,
                   cwms_time_zone tz
             where pl.location_code = cwms_loc.get_location_code(l_office_code, l_location_id)
               and tz.time_zone_code = nvl(pl.time_zone_code, 0);
            if l_time_zone = 'Unknown or Not Applicable' then
               l_time_zone := 'UTC';
            end if;               
         else
            l_time_zone := p_time_zone;
         end if;
      end if;
      l_effective_date := cwms_util.change_timezone(l_effective_date, l_time_zone, 'UTC');
      
      if cwms_util.is_true(p_match_date) then
         select rating_code
           into l_rating_code
           from at_rating
          where rating_spec_code = l_rating_spec_code
            and effective_date = l_effective_date;
      else            
         select rating_code
           into l_rating_code
           from at_rating
          where rating_spec_code = l_rating_spec_code
            and effective_date = 
                ( select max(effective_date)
                    from at_rating
                   where rating_spec_code = l_rating_spec_code
                     and effective_date <= l_effective_date
                );
      end if;
      
      return l_rating_code;
   end;      
end;
/
show errors;

create type rating_tab_t as table of rating_t;
/
show errors;

create type stream_rating_t under rating_t (
-- office_id      varchar2(16),
-- rating_id      varchar2(339),
-- effective_date date,
-- create_date    date,
-- active_flag    varchar2(1),
-- formula        varchar2(1000),
-- description    varchar2(256),
-- rating_info    rating_ind_parameter_t,
   offsets        rating_t,
   shifts         rating_tab_t,
   
   constructor function stream_rating_t(
      p_rating_code in number)
   return self as result,
   
   constructor function stream_rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   
   overriding member procedure init(
      p_rating_code in number),
   
   overriding member procedure store(
      p_fail_if_exists in varchar2)
);
/
show errors;

create type body stream_rating_t
as
   constructor function stream_rating_t(
      p_rating_code in number)
   return self as result
   is
   begin
      (self as rating_t).init(p_rating_code);
      self.init(p_rating_code);
      return;
   end;
   
   constructor function stream_rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result
   is
      l_rating_code number(10);
   begin
      l_rating_code := rating_t.get_rating_code(
         p_rating_id,
         p_effective_date,
         p_match_date,
         p_time_zone,
         p_office_id);
         
      (self as rating_t).init(l_rating_code);         
      self.init(l_rating_code);
      return;
   end;
   
   overriding member procedure init(
      p_rating_code in number)
   is
      l_shifts_codes number_tab_t := number_tab_t();
      l_offsets_code number(10);
      l_time_zone    varchar2(28);
   begin
      begin
         select r.rating_code bulk collect
           into l_shifts_codes
           from at_rating r,
                at_rating_spec rs,
                at_rating_template rt
          where ref_rating_code = p_rating_code
            and rs.rating_spec_code = r.rating_spec_code
            and rt.template_code = rs.template_code
            and rt.parameters_id = 'Stage;Stage-Shift'
       order by r.effective_date;
      exception
         when no_data_found then null;
      end;
         
      if l_shifts_codes.count > 0 then
         select tz.time_zone_name
           into l_time_zone
           from at_rating r,
                at_rating_spec rs,
                at_physical_location pl,
                cwms_time_zone tz
          where r.rating_code = p_rating_code
            and rs.rating_spec_code = r.rating_spec_code
            and pl.location_code = rs.location_code
            and tz.time_zone_code = nvl(pl.time_zone_code, 0);
               
         if l_time_zone = 'Unknown or Not Applicable' then
            l_time_zone := 'UTC';
         end if;
         
         self.shifts := rating_tab_t();
         self.shifts.extend(l_shifts_codes.count);
         for i in 1..l_shifts_codes.count loop
            self.shifts(i) := rating_t(l_shifts_codes(i));
            self.shifts(i).effective_date := cwms_util.change_timezone(
               self.shifts(i).effective_date, 
               'UTC', 
               l_time_zone);
            self.shifts(i).create_date := cwms_util.change_timezone(
               self.shifts(i).create_date, 
               'UTC', 
               l_time_zone);
         end loop;
      end if;
               
      begin
         select r.rating_code
           into l_offsets_code
           from at_rating r,
                at_rating_spec rs,
                at_rating_template rt
          where ref_rating_code = p_rating_code
            and rs.rating_spec_code = r.rating_spec_code
            and rt.template_code = rs.template_code
            and rt.parameters_id = 'Stage;Stage-Offset';
            
         self.offsets := rating_t(l_offsets_code);            
         self.offsets.effective_date := self.effective_date;
         self.offsets.create_date    := self.create_date;
      exception
         when no_data_found then null;
      end;
   end;      
   
   overriding member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rating_code number(10);
      l_ref_rating_code number(10);
   begin
      (self as rating_t).store(l_ref_rating_code, p_fail_if_exists);
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).store(l_rating_code, 'F');
            update at_rating
               set ref_rating_code = l_ref_rating_code
             where rating_code = l_rating_code; 
         end loop;
      end if;
      if self.offsets is not null then
         self.offsets.store(l_rating_code, 'F');
         update at_rating
            set ref_rating_code = l_ref_rating_code
          where rating_code = l_rating_code; 
      end if;
   end;      
end;
/
show errors;

commit;
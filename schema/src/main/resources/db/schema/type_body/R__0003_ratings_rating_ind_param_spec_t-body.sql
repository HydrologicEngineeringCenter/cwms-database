create or replace type body rating_ind_param_spec_t
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
      if p_xml.existsnode('//ind-parameter-spec') = 1 then
         l_xml := get_node(p_xml, '//ind-parameter-spec');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <ind-parameter-spec> element');
      end if;
      self.parameter_position := get_number(l_xml, '/ind-parameter-spec/@position');
      if self.parameter_position is null then
         cwms_err.raise(
            'ERROR',
            'Required "position" attribute not found in <ind-parameter-spec> element');
      end if;
      self.parameter_id := get_text(l_xml, '/ind-parameter-spec/parameter');
      if self.parameter_id is null then
         cwms_err.raise(
            'ERROR',
            '<parameter> element not found under <ind-parameter-spec> element');
      end if;
      self.in_range_rating_method := get_text(l_xml, '/ind-parameter-spec/in-range-method');
      if self.in_range_rating_method is null then
         cwms_err.raise(
            'ERROR',
            '<in-range-method> element not found under <ind-parameter-spec> element');
      end if;
      self.out_range_low_rating_method := get_text( l_xml, '/ind-parameter-spec/out-range-low-method');
      if self.out_range_low_rating_method is null then
         cwms_err.raise(
            'ERROR',
            '<out-range-low-method> element not found under <ind-parameter-spec> element');
      end if;
      self.out_range_high_rating_method := get_text(l_xml, '/ind-parameter-spec/out-range-high-method');
      if self.out_range_high_rating_method is null then
         cwms_err.raise(
            'ERROR',
            '<out-range-high-method> element not found under <ind-parameter-spec> element');
      end if;
      self.validate_obj;
      return;
   end;

   member procedure validate_obj
   is
      l_code number(14);
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
         l_code := cwms_util.get_base_param_code(self.parameter_id, 'T');
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
         l_code := cwms_rating.get_rating_method_code(self.in_range_rating_method);
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
         l_code := cwms_rating.get_rating_method_code(self.out_range_low_rating_method);
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
         l_code := cwms_rating.get_rating_method_code(self.out_range_high_rating_method);
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
   begin
      return cwms_rating.get_rating_method_code(p_rating_id);
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
               || cwms_rating.separator1
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

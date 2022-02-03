create or replace type body rating_spec_t
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
      l_parts := cwms_util.split_text(p_rating_id, cwms_rating.separator1);
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating specification');
      end if;
      init(l_parts(1), l_parts(2)||cwms_rating.separator1||l_parts(3), l_parts(4), p_office_id);
      return;
   end;

   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml            xmltype;
      l_node           xmltype;
      l_rating_spec_id varchar2(380);
      l_parts          str_tab_t;
      l_text           varchar2(64);
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
      l_xml := get_node(p_xml, '//rating-spec');
      if l_xml is null then
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating-spec> element');
      end if;
      self.office_id := get_text(l_xml, '/rating-spec/@office-id');
      if self.office_id is null then
         cwms_err.raise(
            'ERROR',
            'Attribute "office-id" not found in <rating-spec> element');
      end if;
      l_rating_spec_id := get_text(l_xml, '/rating-spec/rating-spec-id');
      if l_rating_spec_id is null then
         cwms_err.raise(
            'ERROR',
            'Missing <rating-spec-id> element under <rating-spec> element');
      end if;
      self.template_id := get_text(l_xml, '/rating-spec/template-id');
      if self.template_id is null then
         cwms_err.raise(
            'ERROR',
            'Missing <template-id> element under <rating-spec> element');
      end if;
      self.location_id := get_text(l_xml, '/rating-spec/location-id');
      if self.location_id is null then
         cwms_err.raise(
            'ERROR',
            'Missing <location-id> element under <rating-spec> element');
      end if;
      self.version := get_text(l_xml, '/rating-spec/version');
      if self.version is null then
         cwms_err.raise(
            'ERROR',
            'Missing <version> element under <rating-spec> element');
      end if;
      self.source_agency_id := get_text(l_xml, '/rating-spec/source-agency');
      self.in_range_rating_method := get_text(l_xml, '/rating-spec/in-range-method');
      if self.in_range_rating_method is null then
         cwms_err.raise(
            'ERROR',
            'Missing <in-range-method> element under <rating-spec> element');
      end if;
      self.out_range_low_rating_method := get_text(l_xml, '/rating-spec/out-range-low-method');
      if self.out_range_low_rating_method is null then
         cwms_err.raise(
            'ERROR',
            'Missing <out-range-high-method> element under <rating-spec> element');
      end if;
      self.out_range_high_rating_method := get_text(l_xml, '/rating-spec/out-range-high-method');
      if self.out_range_high_rating_method is null then
         cwms_err.raise(
            'ERROR',
            'Missing <out-range-high-method> element under <rating-spec> element');
      end if;
      l_text := get_text(l_xml, '/rating-spec/active');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <active> element under <rating-spec> element');
      else
         case l_text
            when 'true'  then self.active_flag := 'T';
            when '1'     then self.active_flag := 'T';
            when 'false' then self.active_flag := 'F';
            when '0'     then self.active_flag := 'F';
            else
               cwms_err.raise(
                  'ERROR',
                  'Invalid value for <active> element under <rating-spec> element: '
                  ||l_text
                  ||', should be 1, 0, true or false');
         end case;
      end if;
      l_text := get_text(l_xml, '/rating-spec/auto-update');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <auto-update> element under <rating-spec> element');
      else
         case l_text
            when 'true'  then self.auto_update_flag := 'T';
            when '1'     then self.auto_update_flag := 'T';
            when 'false' then self.auto_update_flag := 'F';
            when '0'     then self.auto_update_flag := 'F';
            else
               cwms_err.raise(
                  'ERROR',
                  'Invalid value for <auto-update> element under <rating-spec> element: '
                  ||l_text
                  ||', should be 1, 0, true or false');
         end case;
      end if;
      l_text := get_text(l_xml, '/rating-spec/auto-activate');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <auto-activate> element under <rating-spec> element');
      else
         case l_text
            when 'true'  then self.auto_activate_flag := 'T';
            when '1'     then self.auto_activate_flag := 'T';
            when 'false' then self.auto_activate_flag := 'F';
            when '0'     then self.auto_activate_flag := 'F';
            else
               cwms_err.raise(
                  'ERROR',
                  'Invalid value for <auto-activate> element under <rating-spec> element: '
                  ||l_text
                  ||', should be 1, 0, true or false');
         end case;
      end if;
      l_text := get_text(l_xml, '/rating-spec/auto-migrate-extension');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <auto-migrate-extension> element under <rating-spec> element');
      else
         case l_text
            when 'true'  then self.auto_migrate_ext_flag := 'T';
            when '1'     then self.auto_migrate_ext_flag := 'T';
            when 'false' then self.auto_migrate_ext_flag := 'F';
            when '0'     then self.auto_migrate_ext_flag := 'F';
            else
               cwms_err.raise(
                  'ERROR',
                  'Invalid value for <auto-migrate-extension> element under <rating-spec> element: '
                  ||l_text
                  ||', should be 1, 0, true or false');
         end case;
      end if;
      for i in 1..9999999 loop
         l_node := get_node(l_xml, '/rating-spec/ind-rounding-specs/ind-rounding-spec['||i||']');
         exit when l_node is null;
         if i = 1 then
            self.ind_rounding_specs := str_tab_t();
         end if;
         self.ind_rounding_specs.extend;
         if get_number(l_node, '/@position') != i then
            cwms_err.raise(
               'ERROR',
               'Attribute "position" is '
               ||nvl(get_text(l_node, '/@position'), '<NULL>')
               ||' on <ind-rounding-spec> number '||i||' under <rating-spec> element, should be '||i);
         end if;
         self.ind_rounding_specs(i) := get_text(l_node, '/.');
      end loop;
      self.dep_rounding_spec := get_text(l_xml, '/rating-spec/dep-rounding-spec');
      if self.dep_rounding_spec is null then
         cwms_err.raise(
            'ERROR',
            'Missing <dep-rounding-spec> element under <rating-spec> element');
      end if;
      self.description := get_text(l_xml, '/rating-spec/description');
      l_parts := cwms_util.split_text(l_rating_spec_id, cwms_rating.separator1);
      if l_parts.count != 4 then
         cwms_err.raise('ERROR', 'Invalid value for <rating-spec-id> element');
      end if;
      if l_parts(1) != self.location_id then
         cwms_err.raise(
            'ERROR',
            '<rating-spec-id> and <location-id> elements do not agree');
      end if;
      if l_parts(2)||cwms_rating.separator1||l_parts(3) != self.template_id then
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

         self.template_id := l_template_parameters_id || cwms_rating.separator1 || l_template_version;

         self.source_agency_id := cwms_entity.get_entity_id(rec.source_agency_code);

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
      l_rating_spec_code number(14);
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
      LOCATION_ID_NOT_FOUND exception;
      pragma exception_init (LOCATION_ID_NOT_FOUND, -20025);
      l_code     number(14);
      l_template rating_template_t;
      l_invalid  boolean;

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
      begin
         l_code := cwms_loc.get_location_code(self.office_id, self.location_id);
      exception
         when LOCATION_ID_NOT_FOUND then
            declare
               l_base_code number(14);
            begin
               cwms_loc.create_location_raw (
                  l_base_code, -- out param (not used here)
                  l_code,      -- out param
                  cwms_util.get_base_id(self.location_id),
                  cwms_util.get_sub_id(self.location_id),
                  cwms_util.get_db_office_code(self.office_id));
            end;
      end;
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
      l_invalid := upper(self.in_range_rating_method) in ('LOGARITHMIC', 'LOG-LIN', 'LIN-LOG', 'NEAREST');
      if not l_invalid then
         begin
            l_code := cwms_rating.get_rating_method_code(self.in_range_rating_method);
         exception
            when no_data_found then l_invalid := true;
         end;
      end if;
      if l_invalid then
         cwms_err.raise(
            'INVALID_ITEM',
            nvl(self.in_range_rating_method, '<NULL>'),
            'CWMS in-range rating specification method');
      end if;
      ---------------------------------
      -- out_range_low_rating_method --
      ---------------------------------
      l_invalid := upper(self.out_range_low_rating_method) in ('LOGARITHMIC', 'LOG-LIN', 'LIN-LOG', 'PREVIOUS', 'LOWER');
      if not l_invalid then
         begin
            l_code := cwms_rating.get_rating_method_code(self.out_range_low_rating_method);
         exception
            when no_data_found then l_invalid := true;
         end;
      end if;
      if l_invalid then
         cwms_err.raise(
            'INVALID_ITEM',
            nvl(self.out_range_low_rating_method, '<NULL>'),
            'CWMS out-range-low rating specification method');
      end if;
      ----------------------------------
      -- out_range_high_rating_method --
      ----------------------------------
      l_invalid := upper(self.out_range_high_rating_method) in ('LOGARITHMIC', 'LOG-LIN', 'LIN-LOG', 'NEXT', 'HIGHER');
      if not l_invalid then
         begin
            l_code := cwms_rating.get_rating_method_code(self.out_range_high_rating_method);
         exception
            when no_data_found then l_invalid := true;
         end;
      end if;
      if l_invalid then
         cwms_err.raise(
            'INVALID_ITEM',
            nvl(self.out_range_high_rating_method, '<NULL>'),
            'CWMS out-range-high rating specification method');
      end if;
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
         self.ind_rounding_specs := str_tab_t();
         self.ind_rounding_specs.extend(l_template.ind_parameters.count);
      end if;
      for i in 1..self.ind_rounding_specs.count loop
         if self.ind_rounding_specs(i) is null or self.ind_rounding_specs(i) = '????' then
            self.ind_rounding_specs(i) := '4444444444';
         end if;
         validate_rounding_spec(self.ind_rounding_specs(i));
      end loop;
      if self.dep_rounding_spec is null or self.dep_rounding_spec = '????' then
         self.dep_rounding_spec := '4444444444';
      end if;
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
      l_parts := cwms_util.split_text(self.template_id, cwms_rating.separator1);
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
         l_source_agency_code := cwms_entity.get_entity_code(self.source_agency_id, self.office_id);
      end if;
      return l_source_agency_code;
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
      p_fail_if_exists in varchar2)
   is
      l_rec                 at_rating_spec%rowtype;
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
      l_parts := cwms_util.split_text(self.template_id, cwms_rating.separator2);
      l_parts := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
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
      l_location_code := self.get_location_code;
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
               self.office_id||'/'||self.location_id||cwms_rating.separator1||self.template_id||cwms_rating.separator1||self.version);
         end if;
         l_rec.source_agency_code           := self.get_source_agency_code;
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
            l_rec.source_agency_code           := self.get_source_agency_code;
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
         ||'<rating-spec-id>'||self.location_id||cwms_rating.separator1||self.template_id||cwms_rating.separator1||self.version||'</rating-spec-id>'
         ||'<template-id>'||self.template_id||'</template-id>'
         ||'<location-id>'||self.location_id||'</location-id>'
         ||'<version>'||self.version||'</version>'
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
      l_office_code      number(14) := cwms_util.get_office_code(l_office_id);
      l_rating_spec_code number(14);
      l_parts            str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, cwms_rating.separator1);
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
            l_office_id||'/'||p_location_id||cwms_rating.separator1||p_template_id||cwms_rating.separator1||p_version);
   end;

   static function get_rating_spec_code(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return number
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_rating_id, cwms_rating.separator1);
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
            'rating specification');
      end if;
      return rating_spec_t.get_rating_spec_code(
         l_parts(1),
         l_parts(2) || cwms_rating.separator1 || l_parts(3),
         l_parts(4),
         p_office_id);
   end;
end;

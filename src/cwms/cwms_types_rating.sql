/*
drop type stream_rating_t;
drop type rating_tab_t;
drop type rating_t;
drop type rating_ind_param_tab_t;
drop type rating_ind_parameter_t;
drop type rating_value_tab_t;
drop type rating_value_t;
drop type abs_rating_ind_param_t;
drop type rating_value_note_tab_t;
drop type rating_value_note_t;
drop type rating_spec_tab_t;
drop type rating_spec_t;
drop type rating_template_tab_t;
drop type rating_template_t;
drop type rating_ind_par_spec_tab_t;
drop type rating_ind_param_spec_t;
*/
create type rating_ind_param_spec_t
/**
 * Holds information about an independent parameter for ratings
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_logarithmic
 * @see cwms_lookup.method_lin_log
 * @see cwms_lookup.method_log_lin
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type rating_ind_param_spec_tab_t
 *
 * @member parameter_position           The parameter position for this independent parameter. 1 specifies the first (or only) independent parameter, etc...
 * @member parameter_id                 The CWMS parameter identifier for this independent parameter
 * @member in_range_rating_method       The rating behavior when a table of values for this independent parameter encompasses the value to be looked up
 * @member out_range_low_rating_method  The rating behavior when the least value in a table of values for this independent parameter is greater than the value to be looked up
 * @member out_range_high_rating_method The rating behavior when the greatest value in a table of values for this independent parameter is less than the value to be looked up
 */
as object(
   parameter_position           number(1),
   parameter_id                 varchar2(49),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   
   /**
    * Constructs a rating_ind_param_spec_t object from a record in the AT_RATING_IND_PARAM_SPEC table
    *
    * @param p_ind_param_spec_code The primary key for the record
    */
   constructor function rating_ind_param_spec_t(
      p_ind_param_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_param_spec_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_ind_param_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure validate_obj,
   /**
    * Retrieves the CWMS parameter code for this independent parameter
    *
    * @param p_office_id Specifies the office for which to retrieve the parameter code
    */
   member function get_parameter_code(
      p_office_id in varchar2)
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,
   -- not documented
   member function get_out_range_low_rating_code
   return number,
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   -- not documented
   member procedure store(
      p_template_code  in number,
      p_fail_if_exists in varchar2),
   -- not documented
   member function to_xml
   return xmltype,      
   -- not documented
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
/
show errors;

create type rating_ind_par_spec_tab_t
/**
 * Holds information about the independent parameters for a rating
 *
 * @see type rating_ind_param_spec
 */
as table of rating_ind_param_spec_t;
/
show errors;
 
create type rating_template_t
/**
 * Holds information about a rating template.  Rating templates specify "classes"
 * of ratings by specifying the parameters and lookup behaviors. Templates are
 * then incorporated into rating specifications which add additional information
 * such as specific locations.
 *
 * @see type rating_ind_par_spec_tab_t
 * @see type rating_template_tab_t
 *
 * @member office_id         The office that owns the rating template
 * @member parameters_id     The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
 * @member version           The version for this parameter. Used to differentiate this template from others with the same parameters
 * @member ind_parameters    The independent parameter(s) specification for this rating template
 * @member dep_parameter_id  The dependent parameter for this rating template
 * @member description       A description of the rating template
 */
as object(
   office_id         varchar2(16),
   parameters_id     varchar2(256),
   version           varchar2(32),
   ind_parameters    rating_ind_par_spec_tab_t,
   dep_parameter_id  varchar2(49),
   description       varchar2(256),
   /**
    * Constructs a rating_template_t object from unique parameters. The parameters_id field is generated from the p_ind_parameters and p_dep_parmeter_id arguments.
    *
    * @param p_office_id         The office that owns the rating template
    * @param p_version           The version for this parameter. Used to differentiate this template from others with the same parameters
    * @param p_ind_parameters    The independent parameter(s) specification for this rating template
    * @param p_dep_parameter_id  The dependent parameter for this rating template
    * @param p_description       A description of the rating template
    */
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_par_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_template_code the primary key of the table record
    */
   constructor function rating_template_t(
      p_template_code in number)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id     The office that owns the rating template
    * @param p_parameters_id The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
    * @param p_version       The version for this parameter. Used to differentiate this template from others with the same parameters
    */
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id   The office that owns the rating template
    * @param p_template_id The template identifier.  The parameters_id, comprised of the parameters_id and verssion, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    */
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating template
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result,      
   -- not documented
   member procedure init(
      p_template_code in number),
   -- not documented
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_office_code
   return number,
   -- not documented
   member function get_dep_parameter_code
   return number,
   /**
    * Stores the rating template to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating template already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating template already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating template as an XML instance in an XMLTYPE object
    *
    * @return the rating template as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,      
   /**
    * Retrieves the rating template as an XML instance in a CLOB object
    *
    * @return the rating template as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,      
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_id     in varchar2 default null)
   return number result_cache,      
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number)
   return number result_cache,      
   -- not documented
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number result_cache      
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
         l_code := cwms_util.get_base_param_code(self.dep_parameter_id, 'T');
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_PARAM_ID',
               self.dep_parameter_id);
      end;
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
      if l_parts(2) != self.dep_parameter_id then
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

create type rating_template_tab_t
/**
 * Holds a collection of rating templates
 *
 * @see type rating_template_t
 */
as table of rating_template_t;
/
show errors;

create type rating_spec_t
/**
 * Holds a rating specification. A rating specification is identified by a location,
 * a rating template, and a version. It also contains information about
 * <ul>
 *   <li>rating behaviors for when the date of a rated value falls before, within, or after the range of rating effective dates</li>
 *   <li>flags for whether the the specification is active and for automated updating procedures</li>
 *   <li>how values for independent and dependent parameters are rounded for public display</li>
 * </ul>
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type cwms_rating_spec_tab_t
 *
 * @member office_id                    The office that owns the rating spec
 * @member location_id                  The location for the rating spec
 * @member template_id                  The rating template for the rating spec
 * @member version                      The version of the rating spec
 * @member source_agency_id             The agency that provides ratings for the rating spec
 * @member in_range_rating_method       The rating behavior when the effective dates of the ratings encompass the date of a value being rated
 * @member out_range_low_rating_method  The rating behavior when the earliest of effective dates of the ratings is later than the date of a value being rated
 * @member out_range_high_rating_method The rating behavior when the latest of effective dates of the ratings is earlier than the date of a value being rated
 * @member active_flag                  A flag ('T' or 'F') specifying whether this rating spec is active
 * @member auto_update_flag             A flag ('T' or 'F') specifying whether new ratings with this rating spec should automatically be loaded into the database
 * @member auto_activate_flag           A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically be marked as active
 * @member auto_migrate_ext_flag        A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically have previously-defined rating extensions applied
 * @member ind_rounding_specs           USGS-style rounding specifications for each of the independent parameters. Used for public display of data rated by ratings under this rating spec.  Multiple rounding specs are separated by <a href="pkg_cwms_rating.html#separator3">','</a>
 * @member dep_rounding_spec            USGS-style rounding specifications for each of the dependent parameter. Used for public display of data rated by ratings under this rating spec.
 * @member description                  A description of this rating spec
 */
as object(
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
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_spec_code The primary key for the table record
    */
   constructor function rating_spec_t(
      p_rating_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_location_id The location for the rating spec
    * @param p_template_id The rating template for the rating spec
    * @param p_version     The version of the rating spec
    * @param p_office_id   The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return self as result,      
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_id The rating identifier. A rating identifier is comprised of the location_id, template_id, and version, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    * @param p_office_id The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_spec_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating spec
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_spec_code in number),
   -- not documented
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_location_code
   return number,
   -- not documented
   member function get_template_code
   return number,
   -- not documented
   member function get_source_agency_code
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,     
   -- not documented
   member function get_out_range_low_rating_code
   return number,     
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   /**
    * Stores the rating specification to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating specification already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating specification already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),     
   /**
    * Retrieves the rating specification as an XML instance in a CLOB object
    *
    * @return the rating specification as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,
   /**
    * Retrieves the rating specification as an XML instance in an XMLTYPE object
    *
    * @return the rating specification as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   -- not documented
   static function get_rating_spec_code(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return number,      
   -- not documented
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
      l_rating_spec_id varchar2(372);
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
         
         if rec.source_agency_code is not null then
            select loc_group_id
              into self.source_agency_id
              from at_loc_group
             where loc_group_code = rec.source_agency_code;
         end if; 
          
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
      LOCATION_ID_NOT_FOUND exception; 
      pragma exception_init (LOCATION_ID_NOT_FOUND, -20025);
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
      begin
         l_code := cwms_loc.get_location_code(self.office_id, self.location_id);
      exception
         when LOCATION_ID_NOT_FOUND then           
            declare
               l_base_code number(10);
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
               self.office_id||'/'||self.location_id||cwms_rating.separator1||self.template_id||cwms_rating.separator1||self.version);
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
      l_office_code      number(10) := cwms_util.get_office_code(l_office_id);
      l_rating_spec_code number(10);
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
/
show errors;

create type rating_spec_tab_t
/**
 * Holds a collection of rating specifications
 *
 * @see type rating_spec_t
 */
as table of rating_spec_t;
/
show errors;

create type rating_value_note_t
/**
 * Hold a not about a rating value. Rating value notes can apply to multiple rating
 * values.
 *
 * @see type rating_value_note_tab_t
 *
 * @member office_id   The office owning the note
 * @member note_id     The identifier of the note
 * @member description The text of the note
 */
as object(
   office_id   varchar2(16),
   note_id     varchar2(16),
   description varchar2(256),
   -- not documented
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result,      
   -- not documented
   member function get_note_code
   return number,
   /**
    * Stores a rating value not to the databse
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating value note already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating value note already exists
    */
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

create type rating_value_note_tab_t
/**
 * Holds a collection of rating value notes
 *
 * @see type rating_value_note_t
 */
is table of rating_value_note_t;
/
show errors;


create type abs_rating_ind_param_t
/**
 * Abstract base type for type rating_ind_parameter_t.  This type is necessary to
 * allow ratings to rating_ind_parameter_t objects to have recursive self references
 * through the rating_value_tab_t and rating_value_t types.
 *
 * @see type rating_value_t
 * @see type rating_ind_parameter_t
 *
 * @member constructed A flag ('T' or 'F') specifying whether the construction of
 *         the object has been completed
 */
as object(
   constructed varchar2(1),
   -- not documented
   member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   member procedure validate_obj(
      p_parameter_position in number),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_xml
   return xmltype,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
      
) not final
  not instantiable;
/
show errors;

create type body abs_rating_ind_param_t
as

   member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t)
   is begin null; end;      
      
   member procedure validate_obj(
      p_parameter_position in number)
   is begin null; end;

   member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is begin null; end;

   member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is begin null; end;
               
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is begin null; end;
      
   member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is begin null; end;
      
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob
   is begin null; end;
   
   member function to_xml
   return xmltype
   is begin null; end;      
   
   member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
   is begin null; end;      
   
end;
/   
show errors;

create type rating_value_t
/**
 * Holds one lookup value for an independent parameter for a rating, as well as the
 * associated dependent value or dependent rating sub-table.
 *
 * @see type abs_rating_ind_param_t
 * @see type rating_value_tab_t
 *
 * @member ind_value            The independent value
 * @member dep_value            The dependent value if the independent value is for the highest-position (or only) independent parameter
 * @member dep_rating_ind_param The dependent value if the independent value is not for the highest-position independent parameter
 * @member note_id              The identifier of a rating value note, if any
 */
as object(
   ind_value            binary_double,
   dep_value            binary_double,
   dep_rating_ind_param abs_rating_ind_param_t,
   note_id              varchar2(16),
   /**
    * Zero-parameter constructor. Constructs an object with all fields set to NULL.
    */
   constructor function rating_value_t
   return self as result,
   /**
    * Normal constructor.
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_other_ind_hash        A hash value used to identify the collection held in the p_other_ind parameter
    * @param p_ind_value             The independent lookup value for this independent parameter
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    */
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_other_ind_hash        in varchar2,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result,
   /**
    * Stores this rating_value_t object to the databse
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    * @param p_office_id             The office owning the rating value
    */
   member procedure store(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_is_extension          in varchar2,
      p_office_id             in varchar2),
   /**
    * Generates a unique hash code to identify the specified collection of values
    *
    * @param p_other_ind A collection of the values
    *
    * @return a unique hash code to identify the specified collection of values
    */
   static function hash_other_ind(
      p_other_ind in double_tab_t)
   return varchar2      
);
/
show errors;

create type rating_value_tab_t
/**
 * Holds a collection of rating lookup values
 *
 * @see type rating_value_t
 */
as table of rating_value_t;
/
show errors;
create type rating_ind_parameter_t
/**
 * Holds rating lookup values and optionally extension lookup values for an independent parameter
 *
 * @member rating_values    The rating lookup values that apply to this independent parameter
 * @member extension_values The rating extension, if any, that applies to this independent parameter
 */
under abs_rating_ind_param_t(
   rating_values      rating_value_tab_t,
   extension_values   rating_value_tab_t,
   /**
    * Zero-parameter constructor.  Constructs a rating_ind_parameter_t object with all fields NULL
    */
   constructor function rating_ind_parameter_t
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the lowest-position (or only) independent parameter for the
    * specified rating code.
    *
    * @param p_rating_code.  The CWMS rating code for which to create the object.
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the independent parameter position that is one greater than the
    * length of the p_other_ind parameter and will be for the specific independent parameter
    * values specified in the p_other_ind paramter
    *
    * @param p_rating_code The CWMS rating code for which to create the object.
    * @param p_other_ind   The lower-position independent paramter values for which to construct the object
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number,
      p_other_ind   in double_tab_t)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t,
      p_additional_ind            in binary_double)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   overriding member procedure validate_obj(
      p_parameter_position in number),
   -- not documented
   overriding member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   overriding member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   -- not documented
   overriding member function to_xml
   return xmltype,
   -- not documented
   overriding member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double,
   -- not documented
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
      init(rating_ind_parameter_t.get_rating_ind_parameter_code(p_rating_code), null);
      return;
   end;
   

   constructor function rating_ind_parameter_t(
      p_rating_code in number,
      p_other_ind   in double_tab_t)
   return self as result
   is
   begin
      init(rating_ind_parameter_t.get_rating_ind_parameter_code(p_rating_code), p_other_ind);
      return;
   end;
   
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t,
      p_additional_ind            in binary_double)
   return self as result
   is
      l_other_ind double_tab_t := p_other_ind;
   begin
      if l_other_ind is null then
         l_other_ind := double_tab_t();
      end if;
      l_other_ind.extend;
      l_other_ind(l_other_ind.count) := p_additional_ind;
      init(p_rating_ind_parameter_code, l_other_ind);
      return;
   end;
   
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result
   is
      type rating_value_tab_by_id is table of rating_value_tab_t index by varchar2(32767);

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
      l_parts                str_tab_t;
      l_ind_params           str_tab_t;
      l_ind_units            str_tab_t;
      l_processed_points     boolean;
      
      pragma autonomous_transaction; -- allows commit to flush temp table
      
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
      -------------------------------------------------------------------------
      -- local function to build rating by recursing through temporary table --
      -------------------------------------------------------------------------
      function build_rating(
         p_parent_id  in varchar2,
         p_position   in integer default 1)
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
               -- field is not addressable from the more abstract abs_rating_ind_param_t     --
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
                  l_rating_value_tab_id := p_parent_id || cwms_rating.separator3 || rec.ind_value;
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
                  l_rating_param.constructed := 'T';
               -----------------------------------------------------------------------------------
               -- assign the newly-populated rating_ind_parameter_t to the dep_rating_ind_param --
               -- abs_rating_ind_param_t field of l_rating(l_rating.count)                      --
               -----------------------------------------------------------------------------------
               l_rating(l_rating.count).dep_rating_ind_param := l_rating_param;
            end if;         
         end loop;
         return l_rating;
      end;       
   begin
      begin
         l_parts := cwms_util.split_text(get_text(p_xml, '/rating/rating-spec-id'), cwms_rating.separator1);
         l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
         l_ind_params := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      exception
         when others then
            cwms_err.raise('ERROR', 'Cannot determine rating independent parameter(s)');
      end;
      begin
         l_parts := cwms_util.split_text(get_text(p_xml, '/rating/units-id'), cwms_rating.separator2);
         l_ind_units := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      exception
         when others then
            cwms_err.raise('ERROR', 'Cannot determine rating independent unit(s)');
      end;
      for i in 1..l_value_type.count loop
         ----------------------------------------------------------------
         -- for each value type in 'rating-points', 'extension-points' --
         ----------------------------------------------------------------
         l_processed_points := false;
         for j in 1..9999999 loop
            ------------------------------------------------------------
            -- for each <rating-points> or <extension-points> element --
            ------------------------------------------------------------
            l_rating_points := get_node(p_xml, '/rating/'||l_value_type(i)||'['||j||']');
            exit when l_rating_points is null;
            l_processed_points := true;
            l_position := 0;
            l_rating_value_tab_id := l_value_type(i)||'=';
            for k in 1..9999999 loop
               ----------------------------------
               -- for each <other-ind> element --
               ----------------------------------
               l_other_ind := get_node(l_rating_points, '/'||l_value_type(i)||'/other-ind['||k||']');
               exit when l_other_ind is null;
               -----------------------------------------------
               -- extract the position and value attributes --
               -----------------------------------------------
               l_position := get_number(l_other_ind, '/other-ind/@position'); 
               l_value    := get_number(l_other_ind, '/other-ind/@value');
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
               --------------------------------------------------------------------------------------------
               -- ensure values at this position are not decreasing (repeated values OK in this context) --
               --------------------------------------------------------------------------------------------
               if l_value_at_pos(l_position) is not null and l_value < l_value_at_pos(l_position) then
                  cwms_err.raise(
                     'ERROR',
                     'Rating values '
                     ||l_rating_value_tab_id
                     ||': independent values do not monotonically increase after value '
                     ||cwms_rounding.round_dt_f(l_value_at_pos(l_position), '9999999999'));
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
                  l_rating_value_tab_id := l_rating_value_tab_id || cwms_rating.separator3 || l_value_at_pos(l_position);
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
               l_point := get_node(l_rating_points, '/'||l_value_type(i)||'/point['||k||']');
               exit when l_point is null;
               ------------------------------------------------------------------------------------
               -- extract the required <ind> and <dep> node values, and the optional <note> node --
               ------------------------------------------------------------------------------------
               l_ind_value := get_number(l_point, '/point/ind');
               l_dep_value := get_number(l_point, '/point/dep');
               l_note_text := get_text(l_point, '/point/note');
               --------------------------------------------------
               -- ensure the independent values are increasing --
               --------------------------------------------------
               if l_last_ind_value is not null and l_ind_value <= l_last_ind_value then
                  cwms_err.raise(
                     'ERROR',
                     'Rating values '
                     ||l_rating_value_tab_id
                     ||': independent values do not monotonically increase after value '
                     ||cwms_rounding.round_dt_f(l_last_ind_value, '9999999999'));
               end if;
               ------------------------------------------------------------------------------------------------
               -- create and populate a new rating_value_t object at the end of the l_rating_values variable --
               ------------------------------------------------------------------------------------------------
               l_rating_value := rating_value_t();
               l_rating_value.ind_value        := l_ind_value;
               l_rating_value.dep_value        := l_dep_value;
               l_rating_value.note_id          := l_note_text;
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
         if l_processed_points then
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
         end if;            
      end loop;
      commit; -- flush temporary table
      self.constructed := 'T';
      validate_obj(1);
      return;
   end;
   
   overriding member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t)
   is
      l_parameter_position number(1);
      l_other_ind_hash     varchar2(40);
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
         l_other_ind_hash := rating_value_t.hash_other_ind(p_other_ind);
         self.rating_values := rating_value_tab_t();
         for rec2 in
            (  select ind_value
                 from at_rating_value
                where rating_ind_param_code = rec.rating_ind_param_code
                  and other_ind_hash = l_other_ind_hash
             order by ind_value
            )
         loop
            self.rating_values.extend;
            self.rating_values(self.rating_values.count) := rating_value_t(
                  rec.rating_ind_param_code,
                  p_other_ind,
                  l_other_ind_hash, 
                  rec2.ind_value,
                  'F');
         end loop;
         
         self.extension_values := rating_value_tab_t();
         for rec2 in
            (  select ind_value
                 from at_rating_extension_value
                where rating_ind_param_code = rec.rating_ind_param_code
                  and other_ind_hash = l_other_ind_hash
             order by ind_value
            )
         loop
            self.extension_values.extend;
            self.extension_values(self.extension_values.count) := rating_value_t(
                  rec.rating_ind_param_code, 
                  p_other_ind,
                  l_other_ind_hash, 
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
      
   overriding member procedure validate_obj(
      p_parameter_position in number)
   is
      l_rating rating_ind_parameter_t;
   begin
      if self.constructed != 'T' then
         cwms_err.raise('ERROR', 'Object is not fully constructed');
      end if;
      -------------------------
      -- rating values table --
      -------------------------
      if self.rating_values is null or self.rating_values.count = 0 then
         cwms_err.raise(
            'ERROR',
            'Rating independent parameter '||p_parameter_position||' has no values');
      else
         for i in 1..self.rating_values.count loop
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
               else
                  self.rating_values(i).dep_rating_ind_param.validate_obj(p_parameter_position + 1);
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
                  ||' rating values do not monotonically increase after value '
                  ||cwms_rounding.round_dt_f(self.rating_values(i-1).ind_value, '9999999999'));
            end if; 
         end loop;
      end if;
      ----------------------------
      -- extension values table --
      ----------------------------
      if self.extension_values is not null then
         for i in 1..self.extension_values.count loop
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
               else
                  self.extension_values(i).dep_rating_ind_param.validate_obj(p_parameter_position + 1);
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
                  ||' extension values do not monotonically increase after value '
                  ||cwms_rounding.round_dt_f(self.extension_values(i-1).ind_value, '9999999999'));
            end if; 
         end loop;
      end if;
   end;

   overriding member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is
      l_ind_factor              binary_double;
      l_ind_offset              binary_double;
      l_ind_param_id            varchar2(49);
      l_ind_unit_id             varchar2(16);
      l_dep_factor              binary_double;
      l_dep_offset              binary_double;
      l_dep_param_id            varchar2(49);
      l_dep_unit_id             varchar2(16);
      l_parts                   str_tab_t;
      l_deepest                 boolean;
      l_rating                  rating_ind_parameter_t;
      l_remaining_parameters_id varchar2(256);
      l_remaining_units_id      varchar2(256);
   begin
      if self.constructed = 'T' then
         l_deepest := instr(p_parameters_id, cwms_rating.separator3) = 0;
         if l_deepest then
            l_parts := cwms_util.split_text(p_parameters_id, cwms_rating.separator2);
            l_ind_param_id := l_parts(1);
            l_dep_param_id := l_parts(2);
            l_parts := cwms_util.split_text(p_units_id, cwms_rating.separator2);
            l_ind_unit_id := l_parts(1);
            l_dep_unit_id := l_parts(2);
            select factor,
                   offset
              into l_dep_factor,
                   l_dep_offset
              from cwms_base_parameter bp,
                   cwms_unit_conversion uc
             where bp.base_parameter_id = cwms_util.get_base_id(l_dep_param_id)
               and uc.to_unit_code = bp.unit_code
               and uc.from_unit_id = l_dep_unit_id;
         else
            l_parts := cwms_util.split_text(p_parameters_id, cwms_rating.separator3);
            l_ind_param_id := l_parts(1);             
            l_parts := cwms_util.split_text(p_units_id, cwms_rating.separator3);
            l_ind_unit_id := l_parts(1);
            l_remaining_parameters_id := substr(p_parameters_id, instr(p_parameters_id, cwms_rating.separator3) + 1);
            l_remaining_units_id := substr(p_units_id, instr(p_units_id, cwms_rating.separator3) + 1);
         end if;
         select factor,
                offset
           into l_ind_factor,
                l_ind_offset
           from cwms_base_parameter bp,
                cwms_unit_conversion uc
          where bp.base_parameter_id = cwms_util.get_base_id(l_ind_param_id)
            and uc.to_unit_code = bp.unit_code
            and uc.from_unit_id = l_ind_unit_id;
         for i in 1..self.rating_values.count loop
            self.rating_values(i).ind_value := 
               self.rating_values(i).ind_value * l_ind_factor + l_ind_offset;
            if l_deepest then
               self.rating_values(i).dep_value := 
                  self.rating_values(i).dep_value * l_dep_factor + l_dep_offset;
            else
               self.rating_values(i).dep_rating_ind_param.convert_to_database_units(
                  l_remaining_parameters_id,
                  l_remaining_units_id);
            end if;
         end loop;
         if self.extension_values is not null then
            for i in 1..self.extension_values.count loop
               self.extension_values(i).ind_value := 
                  self.extension_values(i).ind_value * l_ind_factor + l_ind_offset;
               if l_deepest then
                  self.extension_values(i).dep_value := 
                     self.extension_values(i).dep_value * l_dep_factor + l_dep_offset;
               else
                  self.extension_values(i).dep_rating_ind_param.convert_to_database_units(
                     l_remaining_parameters_id,
                     l_remaining_units_id);
               end if;
            end loop;
         end if;            
      else
         cwms_err.raise('ERROR', 'Object is not fully constructed');
      end if;
   end;

   overriding member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2)
   is
      l_ind_factor              binary_double;
      l_ind_offset              binary_double;
      l_ind_param_id            varchar2(49);
      l_ind_unit_id             varchar2(16);
      l_dep_factor              binary_double;
      l_dep_offset              binary_double;
      l_dep_param_id            varchar2(49);
      l_dep_unit_id             varchar2(16);
      l_parts                   str_tab_t;
      l_deepest                 boolean;
      l_rating                  rating_ind_parameter_t;
      l_remaining_parameters_id varchar2(256);
      l_remaining_units_id      varchar2(256);
   begin
      if self.constructed = 'T' then
         l_deepest := instr(p_parameters_id, cwms_rating.separator3) = 0;
         if l_deepest then
            l_parts := cwms_util.split_text(p_parameters_id, cwms_rating.separator2);
            l_ind_param_id := l_parts(1);
            l_dep_param_id := l_parts(2);
            l_parts := cwms_util.split_text(p_units_id, cwms_rating.separator2);
            l_ind_unit_id := l_parts(1);
            l_dep_unit_id := l_parts(2);
            select factor,
                   offset
              into l_dep_factor,
                   l_dep_offset
              from cwms_base_parameter bp,
                   cwms_unit_conversion uc
             where bp.base_parameter_id = cwms_util.get_base_id(l_dep_param_id)
               and uc.from_unit_code = bp.unit_code
               and uc.to_unit_id = l_dep_unit_id;
         else
            l_parts := cwms_util.split_text(p_parameters_id, cwms_rating.separator3);
            l_ind_param_id := l_parts(1);             
            l_parts := cwms_util.split_text(p_units_id, cwms_rating.separator3);
            l_ind_unit_id := l_parts(1);
            l_remaining_parameters_id := substr(p_parameters_id, instr(p_parameters_id, cwms_rating.separator3) + 1);
            l_remaining_units_id := substr(p_units_id, instr(p_units_id, cwms_rating.separator3) + 1);
         end if;
         select factor,
                offset
           into l_ind_factor,
                l_ind_offset
           from cwms_base_parameter bp,
                cwms_unit_conversion uc
          where bp.base_parameter_id = cwms_util.get_base_id(l_ind_param_id)
            and uc.from_unit_code = bp.unit_code
            and uc.to_unit_id = l_ind_unit_id;
         for i in 1..self.rating_values.count loop
            self.rating_values(i).ind_value := 
               cwms_rounding.round_dd_f(self.rating_values(i).ind_value * l_ind_factor + l_ind_offset, '9999999999');
            if l_deepest then
               self.rating_values(i).dep_value := 
                  cwms_rounding.round_dd_f(self.rating_values(i).dep_value * l_dep_factor + l_dep_offset, '9999999999');
            else
               self.rating_values(i).dep_rating_ind_param.convert_to_native_units(
                  l_remaining_parameters_id,
                  l_remaining_units_id);
            end if;
         end loop;
         if self.extension_values is not null then
            for i in 1..self.extension_values.count loop
               self.extension_values(i).ind_value := 
                  cwms_rounding.round_dd_f(self.extension_values(i).ind_value * l_ind_factor + l_ind_offset, '9999999999');
               if l_deepest then
                  self.extension_values(i).dep_value := 
                     cwms_rounding.round_dd_f(self.extension_values(i).dep_value * l_dep_factor + l_dep_offset, '9999999999');
               else
                  self.extension_values(i).dep_rating_ind_param.convert_to_native_units(
                     l_remaining_parameters_id,
                     l_remaining_units_id);
               end if;
            end loop;
         end if;            
      else
         cwms_err.raise('ERROR', 'Object is not fully constructed');
      end if;
   end;
   
   overriding member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is
      l_rec                at_rating_ind_parameter%rowtype;
      l_office_id          varchar2(16);
      l_value              rating_value_t;
      l_parameter_position number(1);
      l_hash_code          varchar2(40);
   begin
      l_rec.rating_code := p_rating_code;
      l_parameter_position := 
         case p_other_ind is null
            when true  then 1
            when false then p_other_ind.count + 1
         end; 
      begin
         select rips.ind_param_spec_code
           into l_rec.ind_param_spec_code
           from at_rating r,
                at_rating_spec rs,
                at_rating_ind_param_spec rips
          where r.rating_code = p_rating_code
            and rs.rating_spec_code = r.rating_spec_code
            and rips.template_code = rs.template_code
            and rips.parameter_position = l_parameter_position; 
      exception
         when no_data_found then
            cwms_err.raise(
               'ERROR',
               'Invalid parameter position: '||l_parameter_position);
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
         
         l_hash_code := rating_value_t.hash_other_ind(p_other_ind);
         delete
           from at_rating_value
          where rating_ind_param_code = l_rec.rating_ind_param_code
            and other_ind_hash = l_hash_code;
         
         delete
           from at_rating_extension_value
          where rating_ind_param_code = l_rec.rating_ind_param_code
            and other_ind_hash = l_hash_code;
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
            p_other_ind             => p_other_ind, 
            p_is_extension          => 'F',
            p_office_id             => l_office_id);
      end loop;       
          
      if self.extension_values is not null then
         for i in 1..self.extension_values.count loop
            l_value := self.extension_values(i);
            l_value.store(
               p_rating_ind_param_code => l_rec.rating_ind_param_code, 
               p_other_ind             => p_other_ind, 
               p_is_extension          => 'T',
               p_office_id             => l_office_id);
         end loop;       
      end if;
      
      p_rating_ind_param_code := l_rec.rating_ind_param_code;      
   end;      
   
   overriding member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2)
   is
      l_rating_ind_param_code number(10);
   begin
      self.store(
         l_rating_ind_param_code,
         p_rating_code,
         p_other_ind,
         p_fail_if_exists);
   end;
      
   overriding member function to_clob(
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
            l_ind_params.extend;
            l_ind_params(l_ind_params.count) := self.rating_values(i).ind_value;    
            cwms_util.append(l_text, self.rating_values(i).dep_rating_ind_param.to_clob(l_ind_params, p_is_extension));  
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
                     ||cwms_rounding.round_dt_f(l_ind_params(j), '9999999999')  
                     ||'"/>');
               end loop;   
            end if;
            --------------------------------
            -- output the <point> element --
            --------------------------------
            cwms_util.append(l_text, '<point><ind>'
               ||cwms_rounding.round_dt_f(self.rating_values(i).ind_value, '9999999999')
               ||'</ind><dep>'
               ||cwms_rounding.round_dt_f(self.rating_values(i).dep_value, '9999999999')
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
   
   overriding member function to_xml
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
         
   overriding member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
   is             
      type int_tab_t is table of pls_integer;
      l_result                  binary_double;
      l_rat_count               pls_integer;
      l_ext_count               pls_integer;
      i                         pls_integer := 1;
      j                         pls_integer := 1;
      k                         pls_integer := 0;
      l_ind                     double_tab_t;
      l_ndx                     int_tab_t; -- < 0 = extension, > 0 = rating
      l_independent_properties  cwms_lookup.sequence_properties_t;
      l_in_range_behavior       pls_integer;
      l_out_range_low_behavior  pls_integer;
      l_out_range_high_behavior pls_integer;
      l_high_index              pls_integer;
      l_val                     binary_double;
      l_hi_val                  binary_double;
      l_lo_val                  binary_double;
      l_ratio                   binary_double;
      l_independent_log         boolean;
      l_dependent_log           boolean;
   begin      
      if p_ind_values is not null then
         ------------------
         -- sanity check --
         ------------------
         if p_ind_values.count - p_position + 1 = 1 then
            if rating_values(1).dep_value is null then
               cwms_err.raise(
                  'ERROR',
                  'Single input parameter specified where multiple parameters are required');
            end if;
         else
            if rating_values(1).dep_value is not null then
               cwms_err.raise(
                  'ERROR',
                  'Multiple input parameters specified where single parameter is required');
            end if;
         end if;  
         
         l_rat_count := rating_values.count;
         l_ext_count := case extension_values is null
                           when true  then 0
                           when false then extension_values.count
                        end;
         ---------------------------------
         -- build the independent array --
         ---------------------------------                       
         l_ind := double_tab_t();
         l_ind.extend(l_rat_count + l_ext_count);
         l_ndx := int_tab_t();
         l_ndx.extend(l_rat_count + l_ext_count);
         ------------------------------------------------------------
         -- first add any extension values below the rating values --
         ------------------------------------------------------------
         while i <= l_ext_count and 
               extension_values(i).ind_value < rating_values(1).ind_value
         loop          
            k := k + 1;
            l_ind(k) := extension_values(i).ind_value;
            l_ndx(k) := -i;
            i := i + 1;
         end loop;
         --------------------------------
         -- next add the rating values --
         --------------------------------
         while j <= l_rat_count loop
            k := k + 1;
            l_ind(k) := rating_values(j).ind_value;
            l_ndx(k) := j;
            j := j + 1;
         end loop;
         -----------------------------------------------------------
         -- next add any extension values above the rating values --
         -----------------------------------------------------------
         while i <= l_ext_count loop
            if extension_values(i).ind_value > 
               rating_values(l_rat_count).ind_value
            then
               k := k + 1;
               l_ind(k) := extension_values(i).ind_value;
               l_ndx(k) := -i;
            end if;           
            i := i + 1;
         end loop;
         --------------------------------------------------------------------------
         -- finally trim the independent and dependent arrays to the proper size --
         --------------------------------------------------------------------------  
         l_ind.trim(l_rat_count + l_ext_count - k);
         l_independent_properties := cwms_lookup.analyze_sequence(l_ind);
         -----------------------------------------------------
         -- generate lookup behaviors from rating behaviors --
         -----------------------------------------------------
         if cwms_lookup.method_by_name(p_param_specs(p_position).in_range_rating_method) = cwms_lookup.method_lin_log then
            l_in_range_behavior := cwms_lookup.method_linear;
         elsif cwms_lookup.method_by_name(p_param_specs(p_position).in_range_rating_method) = cwms_lookup.method_log_lin then
            l_in_range_behavior := cwms_lookup.method_logarithmic;
         else 
            l_in_range_behavior := cwms_lookup.method_by_name(p_param_specs(p_position).in_range_rating_method);
         end if;
         if cwms_lookup.method_by_name(p_param_specs(p_position).out_range_low_rating_method) = cwms_lookup.method_lin_log then
            l_out_range_low_behavior := cwms_lookup.method_linear;
         elsif cwms_lookup.method_by_name(p_param_specs(p_position).out_range_low_rating_method) = cwms_lookup.method_log_lin then
            l_out_range_low_behavior := cwms_lookup.method_logarithmic;
         else 
            l_out_range_low_behavior := cwms_lookup.method_by_name(p_param_specs(p_position).out_range_low_rating_method);
         end if;
         if cwms_lookup.method_by_name(p_param_specs(p_position).out_range_high_rating_method) = cwms_lookup.method_lin_log then
            l_out_range_high_behavior := cwms_lookup.method_linear;
         elsif cwms_lookup.method_by_name(p_param_specs(p_position).out_range_high_rating_method) = cwms_lookup.method_log_lin then
            l_out_range_high_behavior := cwms_lookup.method_logarithmic;
         else 
            l_out_range_high_behavior := cwms_lookup.method_by_name(p_param_specs(p_position).out_range_high_rating_method);
         end if;
         ---------------------------------------------------------
         -- find the high index for interpolation/extrapolation --
         ---------------------------------------------------------
         l_high_index := cwms_lookup.find_high_index(
            p_ind_values(p_position),
            l_ind,
            l_independent_properties);
         -----------------------------------------------------
         -- find the ratio for interpolation/extrapoloation --
         -----------------------------------------------------
         l_ratio := cwms_lookup.find_ratio(
            l_independent_log,
            p_ind_values(p_position),
            l_ind,
            l_high_index,
            l_independent_properties.increasing_range,
            l_in_range_behavior,
            l_out_range_low_behavior,
            l_out_range_high_behavior);
         if l_ratio is not null then 
            ------------------------------------------      
            -- set log properties on dependent axis --
            ------------------------------------------
            if l_ratio < 0. then
               l_dependent_log := cwms_lookup.method_by_name(p_param_specs(p_position).out_range_low_rating_method) 
                                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
               if l_dependent_log then
                  if cwms_lookup.method_by_name(p_param_specs(p_position).out_range_low_rating_method) 
                     in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin) 
                     and not l_independent_log
                  then
                     ---------------------------------------
                     -- fall back from LOG-LoG to LIN-LIN --
                     ---------------------------------------
                     l_dependent_log := false;
                  end if;
               end if;      
            elsif l_ratio > 1. then
               l_dependent_log := cwms_lookup.method_by_name(p_param_specs(p_position).out_range_high_rating_method) 
                                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
               if l_dependent_log then
                  if cwms_lookup.method_by_name(p_param_specs(p_position).out_range_high_rating_method) 
                     in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin) 
                     and not l_independent_log
                  then
                     ---------------------------------------
                     -- fall back from LOG-LoG to LIN-LIN --
                     ---------------------------------------
                     l_dependent_log := false;
                  end if;
               end if;      
            else
               l_dependent_log := cwms_lookup.method_by_name(p_param_specs(p_position).in_range_rating_method) 
                                  in (cwms_lookup.method_logarithmic, cwms_lookup.method_lin_log);
               if l_dependent_log then
                  if cwms_lookup.method_by_name(p_param_specs(p_position).in_range_rating_method) 
                     in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin) 
                     and not l_independent_log
                  then
                     ---------------------------------------
                     -- fall back from LOG-LoG to LIN-LIN --
                     ---------------------------------------
                     l_dependent_log := false;
                  end if;
               end if;      
            end if;
            if p_ind_values.count - p_position + 1 = 1 then
               ----------------------------
               -- single input parameter --
               ----------------------------
               if l_ratio != 0. then
                  if l_ndx(l_high_index) > 0 then
                     l_hi_val := rating_values(l_ndx(l_high_index)).dep_value;
                  else
                     l_hi_val := extension_values(-l_ndx(l_high_index)).dep_value;
                  end if;
               end if;
               if l_ratio != 1. then
                  if l_ndx(l_high_index-1) > 0 then
                     l_lo_val := rating_values(l_ndx(l_high_index-1)).dep_value;
                  else
                     l_lo_val := extension_values(-l_ndx(l_high_index-1)).dep_value;
                  end if;
               end if;
            else
               -------------------------------
               -- multiple input parameters --
               -------------------------------
               if l_ratio != 0. then 
                  if l_ndx(l_high_index) > 0 then
                     l_hi_val := rating_values(l_ndx(l_high_index)).dep_rating_ind_param.rate(
                        p_ind_values, 
                        p_position+1, 
                        p_param_specs);
                  else
                     l_hi_val := extension_values(-l_ndx(l_high_index)).dep_rating_ind_param.rate(
                        p_ind_values, 
                        p_position+1, 
                        p_param_specs);
                  end if;
               end if;
               if l_ratio != 1.0 then
                  if l_ndx(l_high_index-1) > 0 then
                     l_lo_val := rating_values(l_ndx(l_high_index-1)).dep_rating_ind_param.rate(
                        p_ind_values, 
                        p_position+1, 
                        p_param_specs);
                  else
                     l_lo_val := extension_values(-l_ndx(l_high_index-1)).dep_rating_ind_param.rate(
                        p_ind_values, 
                        p_position+1, 
                        p_param_specs);
                  end if;
               end if;
            end if;
            case l_ratio
               when 0. then
                  l_val := l_lo_val;
               when 1. then         
                  l_val := l_hi_val;
               else
                  ------------------------------------------------------------------
                  -- handle log interpolation/extrapolation on dependent sequence --
                  ------------------------------------------------------------------
                  if l_dependent_log then
                     declare
                        l_log_hi_val binary_double;
                        l_log_lo_val binary_double; 
                     begin
                        begin
                           l_log_hi_val := log(10, l_hi_val);
                           l_log_lo_val := log(10, l_lo_val);
                        exception
                           when others then
                              l_dependent_log := false;
                              if l_independent_log then
                                 ---------------------------------------
                                 -- fall back from LOG-LoG to LIN-LIN --
                                 ---------------------------------------
                                 l_independent_log := false;
                                 l_ratio := cwms_lookup.find_ratio(
                                    l_independent_log,
                                    p_ind_values(p_position),
                                    l_ind,
                                    l_high_index,
                                    l_independent_properties.increasing_range,
                                    cwms_lookup.method_linear,
                                    cwms_lookup.method_linear,
                                    cwms_lookup.method_linear);  
                              end if;
                        end;
                        if l_dependent_log then
                           l_hi_val := l_log_hi_val;
                           l_lo_val := l_log_lo_val;
                        end if;
                     end;
                  end if;
                  -------------------------------
                  -- interpolate / extrapolate --
                  -------------------------------
                  l_val := l_lo_val + l_ratio * (l_hi_val - l_lo_val);
                  --------------------------------------------------------------------
                  -- apply anti-log if log interpolation/extrapolation of dependent --
                  --------------------------------------------------------------------
                  if l_dependent_log then
                     l_val := power(10, l_val);
                  end if;
            end case;
            l_result := l_val;
         end if;
      end if;
      return l_result;
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

create type rating_ind_param_tab_t
/**
 * Holds a collection of rating_ind_parameter_t objects
 *
 * @see type rating_ind_parameter_t
 */
as table of rating_ind_parameter_t;
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
      p_other_ind             in double_tab_t,
      p_other_ind_hash        in varchar2,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result
   is
      l_rec        at_rating_value%rowtype;
   begin
      if cwms_util.is_true(p_is_extension) then
         select *
           into l_rec
           from at_rating_extension_value
          where rating_ind_param_code = p_rating_ind_param_code
            and other_ind_hash = p_other_ind_hash
            and ind_value = p_ind_value;
      else
         select *
           into l_rec
           from at_rating_value
          where rating_ind_param_code = p_rating_ind_param_code
            and other_ind_hash = p_other_ind_hash
            and ind_value = p_ind_value;
      end if;
      
      self.ind_value := l_rec.ind_value;
      self.dep_value := l_rec.dep_value;
      
      if l_rec.dep_rating_ind_param_code is not null then
         self.dep_rating_ind_param := rating_ind_parameter_t(l_rec.dep_rating_ind_param_code, p_other_ind, self.ind_value);
      end if;
      
      if l_rec.note_code is not null then
         select note_id
           into self.note_id
           from at_rating_value_note
          where note_code = l_rec.note_code;
      end if;
      
      return;              
   end;
   
   member procedure store(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_is_extension          in varchar2,
      p_office_id             in varchar2)
   is
      l_rec                  at_rating_value%rowtype;
      l_note_rec             at_rating_value_note%rowtype;
      l_office_code          number(10) := cwms_util.get_office_code(p_office_id);
      l_rating_code          number(10);
      l_rating_ind_parameter rating_ind_parameter_t;
      l_parameter_position   number(1);
      l_other_ind            double_tab_t;
      l_count                simple_integer := 0;
   begin
      ----------------------------------
      -- store the note, if necessary --
      ----------------------------------
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
      ---------------------------------------------
      -- store the dependent rating if necessary --
      ---------------------------------------------
      if self.dep_rating_ind_param is not null then
         select rips.parameter_position
           into l_parameter_position
           from at_rating_ind_parameter rip,
                at_rating_ind_param_spec rips
          where rip.rating_ind_param_code = p_rating_ind_param_code
            and rips.ind_param_spec_code = rip.ind_param_spec_code;

         l_other_ind := p_other_ind;
         if l_other_ind is null then
            l_other_ind := double_tab_t();
         end if;
         l_other_ind.extend;
         if l_other_ind.count != l_parameter_position then
            cwms_err.raise(
               'ERROR',
               'Computed parameter position ('
               ||l_other_ind.count
               ||') does not agree with specified parameter position ('
               ||l_parameter_position
               ||')');
         end if;
         l_other_ind(l_parameter_position) := self.ind_value;
          
         select rating_code
           into l_rating_code
           from at_rating_ind_parameter
          where rating_ind_param_code = p_rating_ind_param_code;
           
         self.dep_rating_ind_param.store(
            p_rating_ind_param_code => l_rec.dep_rating_ind_param_code, --- out parameter
            p_rating_code           => l_rating_code,
            p_other_ind             => l_other_ind,
            p_fail_if_exists        => 'F');
      end if;            
      ----------------------------
      -- store the rating value --
      ----------------------------
      l_rec.rating_ind_param_code     := p_rating_ind_param_code;
      l_rec.other_ind_hash            := rating_value_t.hash_other_ind(p_other_ind);
      l_rec.ind_value                 := self.ind_value;
      l_rec.dep_value                 := self.dep_value;
      l_rec.note_code                 := l_note_rec.note_code;               
         
      if cwms_util.is_true(p_is_extension) then
         -- cwms_err.raise('ERROR', 'Unexpected p_is_extension: '||p_is_extension);
         insert
           into at_rating_extension_value
         values l_rec;
      else
         insert
           into at_rating_value
         values l_rec;
      end if;
   end;      
      
   static function hash_other_ind(
      p_other_ind in double_tab_t)
   return varchar2
   is
      l_text varchar2(32767) := '/';
   begin
      if p_other_ind is not null then
         for i in 1..p_other_ind.count loop
            l_text := l_text || to_char(p_other_ind(i)) || '/';
         end loop;
      end if;
      return rawtohex(dbms_crypto.hash(utl_raw.cast_to_raw(l_text), dbms_crypto.hash_sh1));
   end;      
end;
/
show errors;

create type rating_t
/**
 * Holds a rating
 *
 * @see type rating_ind_parameter_t
 * @see type rating_spec_t
 * @see type stream_rating_t
 * @see type rating_tab_t
 *
 * @member office_id      The office that owns the rating
 * @member rating_spec_id The rating specification identifier
 * @member effective_date The earliest date/time that the rating is to be in effect
 * @member create_date    The date/time that the rating was loaded into the datbase
 * @member active_flag    A flag ('T' or 'F') specifying whether the rating is active
 * @member formula        The formula (algebraic or RPN) for the rating if the rating is formula-based
 * @member native_units   The native units for the rating
 * @member description    The description of the rating
 * @member rating_info    The rating lookup values if the rating is lookup-based
 * @member current_units  A flag ('D' or 'N') specfying whether the lookup values are currently in database storage ('D') or native ('N') units
 * @member current_time   A flag ('D' or 'L') specifying whether the times are currently in database ('D') (=UTC) or rating location local ('L') time zone
 * @member formula_tokens A collection of formula tokens if the rating is formula-based
 */
as object(
   office_id      varchar2(16),
   rating_spec_id varchar2(372),
   effective_date date,
   create_date    date,
   active_flag    varchar2(1),
   formula        varchar2(1000),
   native_units   varchar2(256),
   description    varchar2(256),
   rating_info    rating_ind_parameter_t,
   current_units  varchar2(1), -- 'D' = database, 'N' = native, other = don't know
   current_time   varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   formula_tokens str_tab_t,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_code The primary key of the AT_RATING table
    */
   constructor function rating_t(
      p_rating_code in number)
   return self as result,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function rating_t(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_code in number),
   -- not documented
   member procedure init(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null),
   -- not documented
   member procedure validate_obj,
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   member procedure convert_to_local_time,
   -- not documented
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2),
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   member function to_clob
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,
   -- not documented
   member function get_date(
      p_timestr in varchar2)
   return date,
   /**
    * Returns the number of independent paramters for this rating
    *
    * @return the number of independent paramters for this rating
    */
   member function get_ind_parameter_count
   return pls_integer,
   -- not documented
    member function reverse
    return rating_t,
   -- not documented
   static function get_rating_code(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return number

) not final
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
      l_text    varchar2(64);
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
      l_xml := get_node(p_xml, '//rating[1]');
      if l_xml is null then
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating> element');
      end if;
      self.office_id := get_text(l_xml, '/rating/@office-id');
      if self.office_id is null then
         cwms_err.raise('ERROR', 'Required office-id attribute not found');
      end if;
      self.rating_spec_id := get_text(l_xml, '/rating/rating-spec-id');
      if self.rating_spec_id is null then
         cwms_err.raise('ERROR', 'Required <rating-spec-id> element not found');
      end if;
      l_text := get_text(l_xml, '/rating/effective-date');
      if l_text is null then
         cwms_err.raise('ERROR', 'Required <effective-date> element not found');
      end if;
      self.effective_date := get_date(l_text);
      l_text := get_text(l_xml, '/rating/create-date');
      if l_text is not null then
         self.create_date := get_date(l_text);
      end if;
      l_text := get_text(l_xml, '/rating/active');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <active> element under <rating> element');
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
      self.formula := get_text(l_xml, '/rating/formula');
      self.native_units := get_text(l_xml, '/rating/units-id');
      if self.native_units is null then
         cwms_err.raise('ERROR', 'Required <units-id> element not found');
      end if;
      self.description   := get_text(l_xml, '/rating/description');
      self.rating_info   := rating_ind_parameter_t(l_xml);
      self.current_units := 'N';
      self.current_time  := 'L';
      self.validate_obj;
      return;
   end;

   member procedure init(
      p_rating_code in number)
   is
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
                  ||cwms_rating.separator1
                  ||rec3.parameters_id
                  ||cwms_rating.separator1
                  ||rec3.version
                  ||cwms_rating.separator1
                  ||rec2.version;

               l_ind_param_count := cwms_util.split_text(rec3.parameters_id, cwms_rating.separator3).count;

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
         end loop;
         self.effective_date := rec.effective_date;
         self.create_date    := rec.create_date;
         self.active_flag    := rec.active_flag;
         self.formula        := rec.formula;
         self.native_units   := rec.native_units;
         self.description    := rec.description;
         self.rating_info    := rating_ind_parameter_t(p_rating_code);
         self.current_units  := 'D';
         self.current_time   := 'D';
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
      l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
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
      l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      if l_parts.count != 2 then
         cwms_err.raise(
            'ERROR',
            'Rating specification identifier contains invalid template parameters identifier');
      end if;
      l_params := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      for i in 1..l_params.count loop
         begin
            l_code := cwms_util.get_base_param_code(l_params(i), 'T');
         exception
            when no_data_found then
               cwms_err.raise(
                  'ERROR',
                  'Rating specification identifier contains invalid base parameter: '||l_params(i));
         end;
      end loop;
      begin
         l_code := cwms_util.get_base_param_code(l_parts(2), 'T');
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
         l_parts := cwms_util.split_text(self.native_units, cwms_rating.separator2);
         if l_parts.count != 2 then
            cwms_err.raise(
               'INVALID_ITEM',
               self.rating_spec_id,
               'Rating native units identifier');
         end if;
         l_units := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
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
                     ('+cwms_rating.separator3-cwms_rating.separator3*cwms_rating.separator3/cwms_rating.separator3//cwms_rating.separator3%cwms_rating.separator3^cwms_rating.separator3ABScwms_rating.separator3ACOScwms_rating.separator3ASINcwms_rating.separator3ATANcwms_rating.separator3CEILcwms_rating.separator3COS',
                     'EXPcwms_rating.separator3FLOORcwms_rating.separator3INVcwms_rating.separator3LNcwms_rating.separator3LOGcwms_rating.separator3NEG', 'SIGNcwms_rating.separator3SINcwms_rating.separator3SQRTcwms_rating.separator3TANcwms_rating.separator3TRUNC')
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
               self.formula_tokens := l_tokens;
            end;
         else
            cwms_err.raise(
               'ERROR',
               'Formula and rating points cannot both be specified');
         end if;
      end if;
   end;

   member procedure convert_to_database_units
   is
      l_parts str_tab_t;
   begin
      case self.current_units
         when 'D' then
            null;
         when 'N' then
            l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
            self.rating_info.convert_to_database_units(l_parts(2), self.native_units);
            self.current_units := 'D';
         else
            cwms_err.raise('ERROR', 'Don''t know the current units of the rating object');
      end case;
   end;

   member procedure convert_to_native_units
   is
      l_parts str_tab_t;
   begin
      case self.current_units
         when 'D' then
            l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
            self.rating_info.convert_to_native_units(l_parts(2), self.native_units);
            self.current_units := 'N';
         when 'N' then
            null;
         else
            cwms_err.raise('ERROR', 'Don''t know the current units of the rating object');
      end case;
   end;

   member procedure convert_to_database_time
   is
      l_local_timezone varchar2(28);
      l_location_id    varchar2(49);
   begin
      case self.current_time
         when 'D' then
            null;
         when 'L' then
            l_location_id := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1);
            l_local_timezone := cwms_loc.get_local_timezone(l_location_id, self.office_id);
            if l_local_timezone is null then
               cwms_err.raise('ERROR', 'Location '||l_location_id||' does not have a time zone set');
            end if;
            self.effective_date := cwms_util.change_timezone(self.effective_date, l_local_timezone, 'UTC');
            if self.create_date is not null then
               self.create_date := cwms_util.change_timezone(self.create_date, l_local_timezone, 'UTC');
            end if;
            self.current_time := 'D';
         else
            cwms_err.raise('ERROR', 'Don''t know the current time setting of the rating object');
      end case;
   end;

   member procedure convert_to_local_time
   is
      l_local_timezone varchar2(28);
      l_location_id    varchar2(49);
   begin
      case self.current_time
         when 'D' then
            l_location_id := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1);
            l_local_timezone := cwms_loc.get_local_timezone(l_location_id, self.office_id);
            if l_local_timezone is null then
               cwms_err.raise('ERROR', 'Location '||l_location_id||' does not have a time zone set');
            end if;
            self.effective_date := cwms_util.change_timezone(self.effective_date, 'UTC', l_local_timezone);
            if self.create_date is not null then
               self.create_date := cwms_util.change_timezone(self.create_date, 'UTC', l_local_timezone);
            end if;
            self.current_time := 'L';
         when 'L' then
            null;
         else
            cwms_err.raise('ERROR', 'Don''t know the current time setting of the rating object');
      end case;
   end;

   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2)
   is
      l_rec       at_rating%rowtype;
      l_exists    boolean := true;
      l_clone     rating_t;
      l_msg       sys.aq$_jms_map_message;
      l_msgid     pls_integer;
      i           integer;
   begin
      if self.current_units = 'N' or self.current_time = 'L' then
         l_clone := self;
         l_clone.convert_to_database_units;
         l_clone.convert_to_database_time;
         l_clone.store(p_rating_code, p_fail_if_exists);
         return;
      end if;
      l_rec.rating_spec_code := rating_spec_t.get_rating_spec_code(
         self.rating_spec_id,
         self.office_id);
      l_rec.effective_date := self.effective_date;

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
               ||' (UTC)');
         end if;
      exception
         when no_data_found then
            l_exists := false;
            l_rec.rating_code := cwms_seq.nextval;
      end;

      l_rec.ref_rating_code := null;
      l_rec.create_date     := nvl(self.create_date, cast(systimestamp at time zone 'UTC' as date));
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
         self.rating_info.store(l_rec.rating_code, null, 'F');
      end if;

      p_rating_code := l_rec.rating_code;

      cwms_msg.new_message(l_msg, l_msgid, 'RatingStored');
      l_msg.set_string(l_msgid, 'office_id', self.office_id);
      l_msg.set_string(l_msgid, 'rating_id', self.rating_spec_id);
      l_msg.set_string(l_msgid, 'active',    self.active_flag);
      l_msg.set_long(l_msgid, 'create_date',    cwms_util.to_millis(l_rec.create_date));
      l_msg.set_long(l_msgid, 'effective_date', cwms_util.to_millis(l_rec.effective_date));
      i := cwms_msg.publish_message(l_msg, l_msgid, self.office_id||'_ts_stored');
      cwms_msg.new_message(l_msg, l_msgid, 'RatingStored');
      l_msg.set_string(l_msgid, 'office_id', self.office_id);
      l_msg.set_string(l_msgid, 'rating_id', self.rating_spec_id);
      l_msg.set_string(l_msgid, 'active',    self.active_flag);
      l_msg.set_long(l_msgid, 'create_date',    cwms_util.to_millis(l_rec.create_date));
      l_msg.set_long(l_msgid, 'effective_date', cwms_util.to_millis(l_rec.effective_date));
      i := cwms_msg.publish_message(l_msg, l_msgid, self.office_id||'_realtime_ops');
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
      l_clone          rating_t;
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
      if self.current_units = 'D' or self.current_time = 'D' then
         l_clone := self;
         l_clone.convert_to_native_units;
         l_clone.convert_to_local_time;
         return l_clone.to_clob;
      end if;
      l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
      select tz.time_zone_name
        into l_time_zone
        from at_physical_location pl,
             cwms_time_zone tz
       where pl.location_code = cwms_loc.get_location_code(self.office_id, l_parts(1))
         and tz.time_zone_code = nvl(pl.time_zone_code, 0);
      if l_time_zone = 'Unknown or Not Applicable' then
         l_time_zone := 'UTC';
      end if;
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating office-id="'||self.office_id||'">'
         ||'<rating-spec-id>'||self.rating_spec_id||'</rating-spec-id>'
         ||'<units-id>'||self.native_units||'</units-id>'
         ||'<effective-date>'||cwms_util.get_xml_time(self.effective_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</effective-date>');
      if self.create_date is not null then
         cwms_util.append(l_text, '<create-date>'||cwms_util.get_xml_time(self.create_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</create-date>');
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

   member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t
   is
      l_results     double_tab_t;
      l_inp_length  pls_integer;
      l_ind_set     double_tab_t;
      l_rating_spec rating_spec_t;
      l_template    rating_template_t;
   begin
      if p_ind_values is not null then
         if p_ind_values.count != get_ind_parameter_count then
            -------------------
            -- sanity checks --
            -------------------
            cwms_err.raise(
               'ERROR',
               'Rating '
               ||rating_spec_id
               ||' requires '
               ||get_ind_parameter_count
               ||' independent parameters, '
               ||p_ind_values.count
               ||' specified');
         end if;
         for i in 1..p_ind_values.count loop
            if i = 1 then
               l_inp_length := p_ind_values(i).count;
            else
               if p_ind_values(i).count != l_inp_length then
                  cwms_err.raise(
                     'ERROR', 'Input parameter sequences have inconsistent sizes');
               end if;
            end if;
         end loop;
         ------------------------
         -- perform the rating --
         ------------------------
         l_ind_set := double_tab_t();
         l_results := double_tab_t();
         l_results.extend(l_inp_length);
         for j in 1..l_inp_length loop
            if l_ind_set.count > 0 then
               l_ind_set.trim(l_ind_set.count);
            end if;
            l_ind_set.extend(p_ind_values.count);
            for i in 1..p_ind_values.count loop
               l_ind_set(i) := p_ind_values(i)(j);
            end loop;
            if formula is not null then
               --------------------
               -- formula rating --
               --------------------
               l_results(j) := cwms_util.eval_tokenized_expression(formula_tokens, l_ind_set);
            else
               ------------------
               -- table rating --
               ------------------
               if l_template is null then
                  l_rating_spec := rating_spec_t(rating_spec_id, office_id);
                  l_template := rating_template_t(office_id, l_rating_spec.template_id);
               end if;
               l_results(j) := rating_info.rate(l_ind_set, 1, l_template.ind_parameters);
            end if;
         end loop;
      end if;
      return l_results;
   end;

   member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t
   is
      l_ind_values double_tab_tab_t;
   begin
      if p_ind_values is not null then
         l_ind_values := double_tab_tab_t();
         l_ind_values.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_ind_values(i) := double_tab_t(p_ind_values(i));
         end loop;
      end if;
      return rate(l_ind_values);
   end;

   member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double
   is
      l_results    double_tab_t;
      l_ind_values double_tab_tab_t := double_tab_tab_t();
   begin
      l_ind_values.extend(p_ind_values.count);
      for i in 1..p_ind_values.count loop
         l_ind_values(i) := double_tab_t(p_ind_values(i));
      end loop;
      l_results := rate(l_ind_values);
      return l_results(1);
   end;

   member function rate(
      p_ind_value in binary_double)
   return binary_double
   is
      l_results double_tab_t;
   begin
      l_results := rate(double_tab_tab_t(double_tab_t(p_ind_value)));
      return l_results(1);
   end;

   member function rate(
      p_ind_values in tsv_array)
   return tsv_array
   is
      l_results tsv_array;
      l_values  double_tab_t;
   begin
      if p_ind_values is not null then
         l_values := double_tab_t();
         l_values.extend(p_ind_values.count);
         l_results := tsv_array();
         l_results.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_values(i) := case cwms_ts.quality_is_missing(p_ind_values(i)) or
                                cwms_ts.quality_is_rejected(p_ind_values(i))
                              when true  then null
                              when false then p_ind_values(i).value
                           end;
         end loop;
         l_values := rate(l_values);
         for i in 1..p_ind_values.count loop
            l_results(i).date_time    := p_ind_values(i).date_time;
            l_results(i).value        := l_values(i);
            l_results(i).quality_code := case l_values(i) is null
                                            when true  then 5
                                            when false then 0
                                         end;
         end loop;
      end if;
      return l_results;
   end;

   member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array
   is
      l_results ztsv_array;
      l_values  double_tab_t;
   begin
      if p_ind_values is not null then
         l_values := double_tab_t();
         l_values.extend(p_ind_values.count);
         l_results := ztsv_array();
         l_results.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_values(i) := case cwms_ts.quality_is_missing(p_ind_values(i)) or
                                cwms_ts.quality_is_rejected(p_ind_values(i))
                              when true  then null
                              when false then p_ind_values(i).value
                           end;
         end loop;
         l_values := rate(l_values);
         for i in 1..p_ind_values.count loop
            l_results(i).date_time    := p_ind_values(i).date_time;
            l_results(i).value        := l_values(i);
            l_results(i).quality_code := case l_values(i) is null
                                            when true  then 5
                                            when false then 0
                                         end;
         end loop;
      end if;
      return l_results;
   end;

   member function rate(
      p_ind_value in tsv_type)
   return tsv_type
   is
      l_values tsv_array;
   begin
      l_values := rate(tsv_array(p_ind_value));
      return l_values(1);
   end;

   member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type
   is
      l_values ztsv_array;
   begin
      l_values := rate(ztsv_array(p_ind_value));
      return l_values(1);
   end;

   member function reverse
   return rating_t
   is
      l_clone    rating_t;
      l_spec     rating_spec_t;
      l_template rating_template_t;
      l_changed  boolean := false;
      l_parts    str_tab_t;
   begin
      ------------------------------------------------------------------
      -- clone the rating, reversing independent and dependent values --
      ------------------------------------------------------------------
      l_clone := self;
      for i in 1..rating_info.rating_values.count loop
         l_clone.rating_info.rating_values(i).ind_value := rating_info.rating_values(i).dep_value;
         l_clone.rating_info.rating_values(i).dep_value := rating_info.rating_values(i).ind_value;
      end loop;
      if rating_info.extension_values is not null then
         for i in 1..rating_info.extension_values.count loop
            l_clone.rating_info.extension_values(i).ind_value := rating_info.extension_values(i).dep_value;
            l_clone.rating_info.extension_values(i).dep_value := rating_info.extension_values(i).ind_value;
         end loop;
      end if;
      ---------------------------------------------------
      -- fixup units and axis-dependent rating methods --
      ---------------------------------------------------
      l_parts := cwms_util.split_text(l_clone.native_units, cwms_rating.separator2);
      l_clone.native_units := l_parts(2)||cwms_rating.separator2||l_parts(1);
      l_spec     := rating_spec_t(rating_spec_id, office_id);
      l_template := rating_template_t(office_id, l_spec.template_id);
      case l_template.ind_parameters(1).in_range_rating_method
         when 'LOG-LIN' then
            l_template.ind_parameters(1).in_range_rating_method := 'LIN-LOG';
            l_changed := true;
         when 'LIN-LOG' then
            l_template.ind_parameters(1).in_range_rating_method := 'LOG-LIN';
            l_changed := true;
         else
            null;
      end case;
      case l_template.ind_parameters(1).out_range_low_rating_method
         when 'LOG-LIN' then
            l_template.ind_parameters(1).out_range_low_rating_method := 'LIN-LOG';
            l_changed := true;
         when 'LIN-LOG' then
            l_template.ind_parameters(1).out_range_low_rating_method := 'LOG-LIN';
            l_changed := true;
         else
            null;
      end case;
      case l_template.ind_parameters(1).out_range_high_rating_method
         when 'LOG-LIN' then
            l_template.ind_parameters(1).out_range_high_rating_method := 'LIN-LOG';
            l_changed := true;
         when 'LIN-LOG' then
            l_template.ind_parameters(1).out_range_high_rating_method := 'LOG-LIN';
            l_changed := true;
         else
            null;
      end case;
      if l_changed then
         l_template.version := substr(l_template.version, 1, least(length(l_template.version), 28))||'$REV';
         l_template.store('F');
         l_spec.template_id := l_template.parameters_id||cwms_rating.separator1||l_template.version;
         l_spec.version := substr(l_spec.version, 1, least(length(l_spec.version), 28))||'$REV';
         l_spec.store('F');
         l_clone.rating_spec_id := l_spec.location_id||cwms_rating.separator1||l_spec.template_id||cwms_rating.separator1||l_spec.version;
      end if;

      return l_clone;
   end;

   member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_values);
   end;

   member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_value);
   end;

   member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_values);
   end;

   member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_values);
   end;

   member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_value);
   end;

   member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type
   is
      l_reversed rating_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a rating with '
            ||get_ind_parameter_count
            ||' independent parameters ('
            ||rating_spec_id
            ||')');
      elsif formula is not null then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse rate through a formula-based rating ('
            ||rating_spec_id
            ||')');
      end if;
      l_reversed := self.reverse;
      return l_reversed.rate(p_dep_value);
   end;

   member function get_date(p_timestr in varchar2) return date
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
         if l_timestr = 'Z' then
            l_timestr := 'UTC';
         else
            l_timestr := 'Etc/GMT'
            ||case substr(l_timestr, 1, 1)
                 when '+' then '-' || to_number(substr(l_timestr, 2, 2))
                 when '-' then '+' || to_number(substr(l_timestr, 2, 2))
              end;
         end if;
         l_parts    := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
         l_timezone := cwms_loc.get_local_timezone(l_parts(1), self.office_id);
         l_date     := cwms_util.change_timezone(l_date, l_timestr, l_timezone);
      end if;
      return l_date;
   end;

   member function get_ind_parameter_count
   return pls_integer
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(rating_spec_id, cwms_rating.separator1);
      l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator3);
      return l_parts.count;
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
      l_parts := cwms_util.split_text(p_rating_spec_id, cwms_rating.separator1);
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
         l_effective_date := sysdate + 1;
      else
         l_effective_date := p_effective_date;
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
         l_effective_date := cwms_util.change_timezone(l_effective_date, l_time_zone, 'UTC');
      end if;

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

create type rating_tab_t
/**
 * Holds a collection of ratings
 *
 * @see type rating_t
 */
as table of rating_t;
/
show errors;

create type stream_rating_t
/**
 * Holds a USGS-style stream rating with shifts and offsets
 *
 * @see type rating_t
 *
 * @member offsets The logarithmic stage interpolation offsets, if any to use with the rating
 * @member shifts  The stage shifts, if any, to use with the rating
 */
under rating_t (
-- office_id      varchar2(16),
-- rating_spec_id varchar2(372),
-- effective_date date,
-- create_date    date,
-- active_flag    varchar2(1),
-- formula        varchar2(1000),
-- native_units   varchar2(256),
-- description    varchar2(256),
-- rating_info    rating_ind_parameter_t,
-- current_units  varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time   varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   offsets        rating_t,
   shifts         rating_tab_t,
   
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_code The primary key of the AT_RATING table
    */
   constructor function stream_rating_t(
      p_rating_code in number)
   return self as result,
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function stream_rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function stream_rating_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_code in number),
   -- not documented
   overriding member procedure validate_obj,
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   overriding member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   overriding member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   overriding member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   overriding member procedure convert_to_local_time,
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   overriding member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,      
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,     
   -- not documented
   member procedure trim_to_effective_date(
      p_date_time in date),
   -- not documented
   member procedure trim_to_create_date(
      p_date_time in date),
   -- not documented
   member function latest_shift_date
   return date      
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

   constructor function stream_rating_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml              xmltype;
      l_node             xmltype;
      l_shift            xmltype;
      l_offsets          xmltype;
      l_rating_points    xmltype;
      l_point            xmltype;
      l_timestr          varchar2(32);
      l_location_id      varchar2(49);
      l_ind_param        varchar2(16);
      l_template_version varchar2(32);
      l_rating_version   varchar2(32);
      l_parts            str_tab_t;
      l_skipped          pls_integer;
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
      ----------------------------
      -- get the rating element --
      ----------------------------
      l_xml := get_node(p_xml, '//usgs-stream-rating[1]');
      if l_xml is null then
         cwms_err.raise(
            'ERROR',
            'Cannot locate <usgs-stream-rating> element');
      end if;
      -----------------------
      -- get the office id --
      -----------------------
      self.office_id := get_text(l_xml, '/usgs-stream-rating/@office-id');
      if self.office_id is null then
         cwms_err.raise('ERROR', 'Required office-id attribute not found');
      end if;
      -------------------------
      -- get the rating spec --
      -------------------------
      self.rating_spec_id := get_text(l_xml, '/usgs-stream-rating/rating-spec-id');
      if self.rating_spec_id is null then
         cwms_err.raise('ERROR', 'Required <rating-spec-id> element not found');
      end if;
      l_parts             := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
      l_location_id       := l_parts(1);
      l_template_version  := l_parts(3);
      l_rating_version    := l_parts(4);
      l_parts             := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      l_ind_param         := cwms_util.get_base_id(l_parts(1));
      ----------------------------
      -- get the effective date --
      ----------------------------
      l_timestr := get_text(l_xml, '/usgs-stream-rating/effective-date');
      if l_timestr is null then
         cwms_err.raise('ERROR', 'Required <effective-date> element not found');
      end if;
      self.effective_date := (self as rating_t).get_date(l_timestr);
      -------------------------
      -- get the create date --
      -------------------------
      l_timestr := get_text(l_xml, '/usgs-stream-rating/create-date');
      if l_timestr is not null then
         self.create_date := (self as rating_t).get_date(l_timestr);
      end if;
      -------------------------
      -- get the active flag --
      -------------------------
      self.active_flag :=
         case get_text(l_xml, '/usgs-stream-rating/active')
            when 'true'  then 'T'
            when '1'     then 'T'
            when 'false' then 'F'
            when '0'     then 'F'
            else               null
         end;
      if self.active_flag is null then
         cwms_err.raise(
            'ERROR',
            '<active> element not found or contains invalid text ');
      end if;
      ----------------------
      -- get the units id --
      ----------------------
      self.native_units := get_text(l_xml, '/usgs-stream-rating/units-id');
      if self.native_units is null then
         cwms_err.raise('ERROR', 'Required <units-id> element not found');
      end if;
      -------------------------
      -- get the description --
      -------------------------
      self.description := get_text(l_xml, '/usgs-stream-rating/description');
      --------------------
      -- for each shift --
      --------------------
      l_skipped := 0;
      for i in 1..9999999 loop
         l_shift := get_node(l_xml, '/usgs-stream-rating/height-shifts['||i||']');
         exit when l_shift is null;
         ----------------------------------------------------
         -- create a new rating_t object to hold the shift --
         ----------------------------------------------------
         if i = 1 then
            self.shifts := rating_tab_t();
         end if;
         self.shifts.extend;
         self.shifts(i-l_skipped) := rating_t(
            self.office_id,              -- office_id
            l_location_id
            ||cwms_rating.separator1||l_ind_param
            ||cwms_rating.separator2||l_ind_param||'-Shift'
            ||cwms_rating.separator1||l_template_version
            ||cwms_rating.separator1||l_rating_version,     -- rating_spec_id
            null,                        -- effective_date
            null,                        -- create_date
            null,                        -- active_flag
            null,                        -- formula
            null,                        -- native_units
            null,                        -- description
            null,                        -- rating_info
            'N',                         -- current_units
            'L',                         -- current_time
            null);                       -- formula_tokens
         ----------------------------------
         -- get the shift effective date --
         ----------------------------------
         l_timestr := get_text(l_shift, '/height-shifts/effective-date');
         if l_timestr is null then
            cwms_err.raise('ERROR', 'Required <effective-date> element not found on shift');
         end if;
         self.shifts(i-l_skipped).effective_date := (self as rating_t).get_date(l_timestr);
         ----------------------------------
         -- get the shift create date --
         ----------------------------------
         l_timestr := get_text(l_shift, '/height-shifts/create-date');
         if l_timestr is not null then
            self.shifts(i-l_skipped).create_date := (self as rating_t).get_date(l_timestr);
         end if;
         -------------------------------
         -- get the shift active flag --
         -------------------------------
         self.shifts(i-l_skipped).active_flag :=
            case get_text(l_shift, '/height-shifts/active')
               when 'true'  then 'T'
               when '1'     then 'T'
               when 'false' then 'F'
               when '0'     then 'F'
               else               null
            end;
         if self.shifts(i-l_skipped).active_flag is null then
            cwms_err.raise(
               'ERROR',
               'Invalid text for <active> element: '
               ||get_text(l_shift, '/height-shifts/active'));
         end if;
         ----------------------------
         -- get the shift units id --
         ----------------------------
         l_parts := cwms_util.split_text(self.native_units, cwms_rating.separator2);
         self.shifts(i-l_skipped).native_units := l_parts(1) || cwms_rating.separator2 || l_parts(1);
         -------------------------------
         -- get the shift description --
         -------------------------------
         self.shifts(i-l_skipped).description := get_text(l_shift, '/height-shifts/description');
         --------------------------
         -- for each shift point --
         --------------------------
         for j in 1..9999999 loop
            l_point := get_node(l_shift, '/height-shifts/point['||j||']');
            exit when l_point is null;
            ------------------------------------------------------------
            -- create a new rating_value_t object for the shift point --
            ------------------------------------------------------------
            if j = 1 then
               self.shifts(i-l_skipped).rating_info := rating_ind_parameter_t(
                  'F',                  -- constructed
                  rating_value_tab_t(), -- rating_values
                  null);                -- extension_values
            end if;
            self.shifts(i-l_skipped).rating_info.rating_values.extend();
            self.shifts(i-l_skipped).rating_info.rating_values(j) := rating_value_t();
            self.shifts(i-l_skipped).rating_info.rating_values(j).ind_value := get_number(l_point, '/point/ind');
            self.shifts(i-l_skipped).rating_info.rating_values(j).dep_value := get_number(l_point, '/point/dep');
            self.shifts(i-l_skipped).rating_info.rating_values(j).note_id   := get_text(l_point, '/point/note');
         end loop;
         self.shifts(i-l_skipped).rating_info.constructed := 'T';
         begin
            self.shifts(i-l_skipped).rating_info.validate_obj(1);
            dbms_output.put_line('shift OK');
         exception
            when others then
               cwms_msg.log_db_message(
                  'stream_rating_t.store',
                  cwms_msg.msg_level_normal,
                  'Rating shift '||i||' skipped due to '||sqlerrm);
               l_skipped := l_skipped + 1;
               self.shifts.trim;
         end;
      end loop;
      l_offsets := get_node(l_xml, '/usgs-stream-rating/height-offsets');
      if l_offsets is not null then
         ------------------------------------------------------
         -- create a new rating_t object to hold the offsets --
         ------------------------------------------------------
         self.offsets := rating_t(
            self.office_id,                      -- office_id
            l_location_id
            ||cwms_rating.separator1||l_ind_param
            ||cwms_rating.separator2||l_ind_param||'-Offset'
            ||cwms_rating.separator1||l_template_version
            ||cwms_rating.separator1||l_rating_version,             -- rating_spec_id
            self.effective_date,                 -- effective_date
            self.create_date,                    -- create_date
            self.active_flag,                    -- active_flag
            null,                                -- formula
            null,                                -- native_units
            'Logarithmic interpolation offsets', -- description
            null,                                -- rating_info
            'N',                                 -- current_units
            'L',                                 -- current_time
            null);                               -- formula_tokens
         ----------------------------
         -- get the offset units id --
         ----------------------------
         l_parts := cwms_util.split_text(self.native_units, cwms_rating.separator2);
         self.offsets.native_units := l_parts(1) || cwms_rating.separator2 || l_parts(1);
         --------------------------
         -- for each offset point --
         --------------------------
         for i in 1..9999999 loop
            l_point := get_node(l_offsets, '/height-offsets/point['||i||']');
            exit when l_point is null;
            ------------------------------------------------------------
            -- create a new rating_value_t object for the offset point --
            ------------------------------------------------------------
            if i = 1 then
               self.offsets.rating_info := rating_ind_parameter_t(
                  'F',                  -- constructed
                  rating_value_tab_t(), -- rating_values
                  null);                -- extension_values
            end if;
            self.offsets.rating_info.rating_values.extend();
            self.offsets.rating_info.rating_values(i) := rating_value_t();
            self.offsets.rating_info.rating_values(i).ind_value := get_number(l_point, '/point/ind');
            self.offsets.rating_info.rating_values(i).dep_value := get_number(l_point, '/point/dep');
            self.offsets.rating_info.rating_values(i).note_id   := get_text(l_point, '/point/note');
         end loop;
         if self.offsets is not null then
            self.offsets.rating_info.constructed := 'T';
            begin
               self.offsets.rating_info.validate_obj(1);
            exception
               when others then
                  cwms_msg.log_db_message(
                     'stream_rating_t.store',
                     cwms_msg.msg_level_normal,
                     'Rating offsets error '||sqlerrm);
                  raise;
            end;
         end if;
      end if;
      l_rating_points := get_node(l_xml, '/usgs-stream-rating/rating-points');
      if l_rating_points is not null then
         ---------------------------
         -- for each rating point --
         ---------------------------
         for i in 1..9999999 loop
            l_point := get_node(l_rating_points, '/rating-points/point['||i||']');
            exit when l_point is null;
            -------------------------------------------------------------
            -- create a new rating_value_t object for the rating point --
            -------------------------------------------------------------
            if i = 1 then
               self.rating_info := rating_ind_parameter_t(
                  'F',                  -- constructed
                  rating_value_tab_t(), -- rating_values
                  null);                -- extension_values
            end if;
            self.rating_info.rating_values.extend();
            self.rating_info.rating_values(i) := rating_value_t();
            self.rating_info.rating_values(i).ind_value := get_number(l_point, '/point/ind');
            self.rating_info.rating_values(i).dep_value := get_number(l_point, '/point/dep');
            self.rating_info.rating_values(i).note_id   := get_text(l_point, '/point/note');
         end loop;
         if self.rating_info is not null then
            self.rating_info.constructed := 'T';
            self.rating_info.validate_obj(1);
         end if;
      end if;
      self.current_units := 'N';
      self.current_time := 'L';
      self.validate_obj;
      return;
   end;

   overriding member procedure init(
      p_rating_code in number)
   is
      l_offsets_code number(10);
   begin
      begin
         select rating_t(r.rating_code) bulk collect
           into self.shifts
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
      self.validate_obj;
   end;

   overriding member procedure validate_obj
   is
      l_parts         str_tab_t;
      l_ind_param     varchar2(256);
      l_dep_param     varchar2(256);
      l_parameters_id varchar2(256);
   begin
      ------------------------
      -- validate as rating --
      ------------------------
      (self as rating_t).validate_obj;
      ------------------------------------------------------
      -- validate Stage;Flow or Elev;Flow base parameters --
      ------------------------------------------------------
      l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
      l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      l_ind_param := l_parts(1);
      l_dep_param := l_parts(2);
      if instr(l_ind_param, cwms_rating.separator3) != 0 or
         (cwms_util.get_base_id(l_ind_param) != 'Stage' and
          cwms_util.get_base_id(l_ind_param) != 'Elev') or
          cwms_util.get_base_id(l_dep_param) != 'Flow'
      then
         l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
         cwms_err.raise(
            'ERROR',
            'Invalid parameters identifier for stream rating: '||l_parts(2));
      end if;
      l_ind_param := cwms_util.get_base_id(l_ind_param);
      ----------------------
      -- validate offsets --
      ----------------------
      if self.offsets is not null then
         begin
            self.offsets.validate_obj;
            if self.offsets.office_id != self.office_id then
               cwms_err.raise('ERROR', 'Offsets office does not match rating office');
            end if;
            l_parts := cwms_util.split_text(self.offsets.rating_spec_id, cwms_rating.separator1);
            l_parameters_id := l_parts(2);
            if l_parameters_id != l_ind_param || cwms_rating.separator2 || l_ind_param || '-Offset' then
               cwms_err.raise('ERROR', 'Invalid offsets parameter id - should be '||l_ind_param||cwms_rating.separator2||l_ind_param||'-Offset');
            end if;
            if self.offsets.effective_date != self.effective_date then
               cwms_err.raise('ERROR', 'Offsets effective date does not match rating effective date');
            end if;
            if (self.offsets.create_date is null) != (self.create_date is null) then
               cwms_err.raise('ERROR', 'Offsets create date does not match rating create date');
            end if;
            if self.create_date is not null then
               if self.offsets.create_date != self.create_date then
                  cwms_err.raise('ERROR', 'Offsets create date does not match rating create date');
               end if;
            end if;
            if self.offsets.formula is not null then
               cwms_err.raise('ERROR', 'Offsets cannot use a formula');
            end if;
            if self.offsets.native_units is null then
               cwms_err.raise('ERROR', 'Offsets must use same unit as rating stage or elevation unit');
            end if;
            l_parts := cwms_util.split_text(self.offsets.native_units, cwms_rating.separator2);
            if l_parts.count != 2 or l_parts(1) != l_parts(2) then
               cwms_err.raise('ERROR', 'Invalid native units for offsets');
            end if;
            if substr(self.native_units, 1, instr(self.native_units, cwms_rating.separator2) - 1) != l_parts(1) then
               cwms_err.raise('ERROR', 'Offsets must use same unit as rating stage or elevation unit');
            end if;
            if self.offsets.rating_info.extension_values is not null then
               cwms_err.raise('ERROR', 'Offsets cannot contain extension values');
            end if;
            if self.offsets.rating_info.rating_values is null then
               cwms_err.raise('ERROR', 'Offsets must contain rating values if specified');
            end if;
            for i in 1..self.offsets.rating_info.rating_values.count loop
               if i > 1 then
                  if self.offsets.rating_info.rating_values(i).ind_value <=
                     self.offsets.rating_info.rating_values(i-1).ind_value
                  then
                     cwms_err.raise(
                        'ERROR',
                        'Offsets stages/elevations do not monotonically increase after value '
                        ||cwms_rounding.round_dt_f(self.offsets.rating_info.rating_values(i-1).ind_value, '9999999999'));
                  end if;
               end if;
               if self.offsets.rating_info.rating_values(i).dep_value is null or
                  self.offsets.rating_info.rating_values(i).dep_rating_ind_param is not null
               then
                  cwms_err.raise('ERROR', 'Offsets must contain offset values as dependent parameter');
               end if;
            end loop;
         exception
            when others then
               cwms_msg.log_db_message(
                  'stream_rating_t.store',
                  cwms_msg.msg_level_normal,
                  'Rating offsets error '||sqlerrm);
               raise;
         end;
      end if;
      ---------------------
      -- validate shifts --
      ---------------------
      if self.shifts is not null then
         for i in reverse 1..self.shifts.count loop
            begin
               self.shifts(i).validate_obj;
               if self.shifts(i).office_id != self.office_id then
                  cwms_err.raise('ERROR', 'Shifts office does not match rating office');
               end if;
               l_parts := cwms_util.split_text(self.shifts(i).rating_spec_id, cwms_rating.separator1);
               l_parameters_id := l_parts(2);
               if l_parameters_id != l_ind_param || cwms_rating.separator2 || l_ind_param || '-Shift' then
                  cwms_err.raise('ERROR', 'Invalid shift parameter id - should be '||l_ind_param||cwms_rating.separator2||l_ind_param||'-Shift');
               end if;
               if self.shifts(i).effective_date < self.effective_date then
                  cwms_err.raise(
                     'ERROR',
                     'Shift '||i||' effective date ('
                     ||self.shifts(i).effective_date
                     ||') is earlier than rating effective date ('
                     ||self.effective_date
                     ||')');
               end if;
               if self.shifts(i).create_date is not null then
                  if self.create_date is null or self.shifts(i).create_date < self.create_date then
                     cwms_err.raise(
                        'ERROR',
                        'Shift '||i||' create date ('
                        ||to_char(self.shifts(i).create_date, 'yyyy/mm/dd hh24:mi:ss')
                        ||') is earlier than rating create date ('
                        ||to_char(self.create_date, 'yyyy/mm/dd hh24:mi:ss')
                        ||')');
                  end if;
               end if;
               if self.shifts(i).formula is not null then
                  cwms_err.raise('ERROR', 'Shifts cannot use a formula');
               end if;
               if self.shifts(i).native_units is null then
                  cwms_err.raise('ERROR', 'Shifts must use same unit as rating stage or elevation unit');
               end if;
               l_parts := cwms_util.split_text(self.shifts(i).native_units, cwms_rating.separator2);
               if l_parts.count != 2 or l_parts(1) != l_parts(2) then
                  cwms_err.raise('ERROR', 'Invalid native units for shifts');
               end if;
               if substr(self.native_units, 1, instr(self.native_units, cwms_rating.separator2) - 1) != l_parts(1) then
                  cwms_err.raise('ERROR', 'Shifts must use same unit as rating stage or elevation unit');
               end if;
               if self.shifts(i).rating_info.extension_values is not null then
                  cwms_err.raise('ERROR', 'Shifts cannot contain extension values');
               end if;
               if self.shifts(i).rating_info.rating_values is null then
                  cwms_err.raise('ERROR', 'Shifts must contain rating values if specified');
               end if;
               for j in 1..self.shifts(i).rating_info.rating_values.count loop
                  if j > 1 then
                     if self.shifts(i).rating_info.rating_values(j).ind_value <=
                        self.shifts(i).rating_info.rating_values(j-1).ind_value
                     then
                        cwms_err.raise(
                           'ERROR',
                           'Shifts stages/elevations do not monotonically increase after value '
                           ||cwms_rounding.round_dt_f(self.shifts(i).rating_info.rating_values(j-1).ind_value, '9999999999'));
                     end if;
                  end if;
                  if self.shifts(i).rating_info.rating_values(j).dep_value is null or
                     self.shifts(i).rating_info.rating_values(j).dep_rating_ind_param is not null
                  then
                     cwms_err.raise('ERROR', 'Shifts must contain shift values as dependent parameter');
                  end if;
               end loop;
            exception
               when others then
                  cwms_msg.log_db_message(
                     'stream_rating_t.validate_obj',
                     cwms_msg.msg_level_normal,
                     'Rating shift '||i||' skipped due to '||sqlerrm);
                  for j in i+1..self.shifts.count loop -- static limits 
                     exit when j > self.shifts.count;  -- dynamically evaluated
                     self.shifts(j-1) := self.shifts(j);
                     self.shifts.trim(1);
                  end loop;
            end;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_database_units
   is
   begin
      (self as rating_t).convert_to_database_units;
      if self.offsets is not null then
         self.offsets.convert_to_database_units;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).convert_to_database_units;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_native_units
   is
   begin
      (self as rating_t).convert_to_native_units;
      if self.offsets is not null then
         self.offsets.convert_to_native_units;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).convert_to_native_units;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_database_time
   is
   begin
      (self as rating_t).convert_to_database_time;
      if self.offsets is not null then
         self.offsets.convert_to_database_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).convert_to_database_time;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_local_time
   is
   begin
      (self as rating_t).convert_to_local_time;
      if self.offsets is not null then
         self.offsets.convert_to_local_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).convert_to_local_time;
         end loop;
      end if;
   end;

   overriding member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rating_code      number(10);
      l_ref_rating_code  number(10);
      l_template         rating_template_t;
      l_parts            str_tab_t;
      l_location_id      varchar2(49);
      l_ind_param        varchar2(16);
      l_template_version varchar2(32);
      l_spec_version     varchar2(23);
      l_spec             rating_spec_t;
      l_rating_spec      rating_spec_t;
      l_clone            stream_rating_t;
   begin
      if self.current_units = 'N' or self.current_time = 'L' then
         l_clone := self;
         l_clone.convert_to_database_units;
         l_clone.convert_to_database_time;
         l_clone.store(p_fail_if_exists);
         return;
      end if;
      l_parts             := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
      l_location_id       := l_parts(1);
      l_template_version  := l_parts(3);
      l_spec_version      := l_parts(4);
      l_parts             := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      l_ind_param         := cwms_util.get_base_id(l_parts(1));
      l_rating_spec       := rating_spec_t(self.rating_spec_id, self.office_id);
      (self as rating_t).store(l_ref_rating_code, p_fail_if_exists);
      if self.shifts is not null then
        l_template := rating_template_t(
            self.office_id,
            l_ind_param||cwms_rating.separator2||l_ind_param||'-Shift',
            l_template_version,
            rating_ind_par_spec_tab_t(
               rating_ind_param_spec_t(
                  1,
                  l_ind_param,
                  'LINEAR',
                  'NEAREST',
                  'NEAREST')),
            l_ind_param||'-Shift',
            'USGS-style rating shifts');
         l_template.store('F');
         l_spec := rating_spec_t(
            self.office_id,
            l_location_id,
            l_template.parameters_id||cwms_rating.separator1||l_template.version,
            l_spec_version,
            l_rating_spec.source_agency_id,
            'LINEAR',
            'LINEAR',
            'NEAREST',
            l_rating_spec.active_flag,
            l_rating_spec.auto_update_flag,
            l_rating_spec.auto_activate_flag,
            'F',
            str_tab_t(l_rating_spec.ind_rounding_specs(1)),
            l_rating_spec.ind_rounding_specs(1),
            'USGS-style rating shifts');
         l_spec.store('F');
         for i in 1..self.shifts.count loop
            self.shifts(i).store(l_rating_code, 'F');
            update at_rating
               set ref_rating_code = l_ref_rating_code
             where rating_code = l_rating_code;
         end loop;
      end if;
      if self.offsets is not null then
         l_template := rating_template_t(
            self.office_id,
            l_ind_param||cwms_rating.separator2||l_ind_param||'-Offset',
            l_template_version,
            rating_ind_par_spec_tab_t(
               rating_ind_param_spec_t(
                  1,
                  l_ind_param,
                  'PREVIOUS',
                  'NEAREST',
                  'NEAREST')),
            l_ind_param||'-Offset',
            'USGS-style logarithmic interpolation offsets');
         l_template.store('F');
         l_spec := rating_spec_t(
            self.office_id,
            l_location_id,
            l_template.parameters_id||cwms_rating.separator1||l_template.version,
            l_spec_version,
            l_rating_spec.source_agency_id,
            'NEAREST',
            'PREVIOUS',
            'NEAREST',
            l_rating_spec.active_flag,
            l_rating_spec.auto_update_flag,
            l_rating_spec.auto_activate_flag,
            'F',
            str_tab_t(l_rating_spec.ind_rounding_specs(1)),
            l_rating_spec.ind_rounding_specs(1),
            'USGS-style logarithmic interpolation offsets');
         l_spec.store('F');
         self.offsets.store(l_rating_code, 'F');
         update at_rating
            set ref_rating_code = l_ref_rating_code
          where rating_code = l_rating_code;
      end if;
   end;

   overriding member function to_clob
   return clob
   is
      l_text  clob;
      l_clone stream_rating_t;
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
      if self.current_units = 'D' or self.current_time = 'D' then
         l_clone := self;
         l_clone.convert_to_native_units;
         l_clone.convert_to_local_time;
         return l_clone.to_clob;
      end if;
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text,
         '<usgs-stream-rating office-id="'||self.office_id||'">'
         ||'<rating-spec-id>'||self.rating_spec_id||'</rating-spec-id>'
         ||'<units-id>'||self.native_units||'</units-id>'
         ||'<effective-date>'||cwms_util.get_xml_time(self.effective_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</effective-date>');
      if self.create_date is not null then
         cwms_util.append(l_text, '<create-date>'||cwms_util.get_xml_time(self.create_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</create-date>');
      end if;
      cwms_util.append(l_text,
         '<active>'
         ||bool_text(cwms_util.is_true(self.active_flag))
         ||'</active>');
      if self.description is not null then
         cwms_util.append(l_text, '<description>'||self.description||'</description>');
      end if;
      -------------------
      -- output shifts --
      -------------------
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            cwms_util.append(l_text,
               '<height-shifts><effective-date>'
               ||cwms_util.get_xml_time(self.shifts(i).effective_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</effective-date>');
            if self.shifts(i).create_date is not null then
               cwms_util.append(l_text, '<create-date>'||cwms_util.get_xml_time(self.shifts(i).create_date, cwms_loc.get_local_timezone(cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1), self.office_id))||'</create-date>');
            end if;
            cwms_util.append(l_text,
               '<active>'
               ||bool_text(cwms_util.is_true(self.shifts(i).active_flag))
               ||'</active>');
            if self.shifts(i).description is not null then
               cwms_util.append(l_text, '<description>'||self.shifts(i).description||'</description>');
            end if;
            for j in 1..self.shifts(i).rating_info.rating_values.count loop
               cwms_util.append(l_text,
                  '<point><ind>'
                  ||cwms_rounding.round_dt_f(self.shifts(i).rating_info.rating_values(j).ind_value, '9999999999')
                  ||'</ind><dep>'
                  ||cwms_rounding.round_dt_f(self.shifts(i).rating_info.rating_values(j).dep_value, '9999999999')
                  ||'</dep>');
               if self.shifts(i).rating_info.rating_values(j).note_id is not null then
                  cwms_util.append(l_text,
                     '<note>'
                     ||self.shifts(i).rating_info.rating_values(j).note_id
                     ||'</note>');
               end if;
               cwms_util.append(l_text, '</point>');
            end loop;
            cwms_util.append(l_text, '</height-shifts>');
         end loop;
      end if;
      -------------------
      -- output offsets -
      -------------------
      if self.offsets is not null then
         cwms_util.append(l_text, '<height-offsets>');
         for i in 1..self.offsets.rating_info.rating_values.count loop
            cwms_util.append(l_text,
               '<point><ind>'
               ||cwms_rounding.round_dt_f(self.offsets.rating_info.rating_values(i).ind_value, '9999999999')
               ||'</ind><dep>'
               ||cwms_rounding.round_dt_f(self.offsets.rating_info.rating_values(i).dep_value, '9999999999')
               ||'</dep>');
            if self.offsets.rating_info.rating_values(i).note_id is not null then
               cwms_util.append(l_text,
                  '<note>'
                  ||self.offsets.rating_info.rating_values(i).note_id
                  ||'</note>');
            end if;
            cwms_util.append(l_text, '</point>');
            end loop;
         cwms_util.append(l_text, '</height-offsets>');
      end if;
      -------------------
      -- rating points --
      -------------------
      cwms_util.append(l_text, '<rating-points>');
      for i in 1..self.rating_info.rating_values.count loop
         cwms_util.append(l_text,
            '<point><ind>'
            ||cwms_rounding.round_dt_f(self.rating_info.rating_values(i).ind_value, '9999999999')
            ||'</ind><dep>'
            ||cwms_rounding.round_dt_f(self.rating_info.rating_values(i).dep_value, '9999999999')
            ||'</dep>');
         if self.rating_info.rating_values(i).note_id is not null then
            cwms_util.append(l_text,
               '<note>'
               ||self.rating_info.rating_values(i).note_id
               ||'</note>');
         end if;
         cwms_util.append(l_text, '</point>');
      end loop;
      cwms_util.append(l_text, '</rating-points></usgs-stream-rating>');
      dbms_lob.close(l_text);
      return l_text;
   end;

   overriding member function to_xml
   return xmltype
   is
   begin
      return xmltype(self.to_clob());
   end;

   overriding member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t
   is
   begin
      if p_ind_values is null then
         return null;
      else
         if p_ind_values.count != 1 then
            cwms_err.raise(
               'ERROR',
               'Rating '
               ||rating_spec_id
               ||' takes 1 independent parameter, '
               ||p_ind_values.count
               ||' specified');
         end if;
         return rate(p_ind_values(1));
      end if;
   end;

   overriding member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t
   is
      l_results double_tab_t;
      l_ztsv    ztsv_array;
   begin
      if p_ind_values is not null then
         l_ztsv := ztsv_array();
         l_ztsv.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_ztsv(i).date_time := sysdate;
            l_ztsv(i).value     := p_ind_values(i);
         end loop;
         l_ztsv := rate(l_ztsv);
         l_results := double_tab_t();
         l_results.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_results(i) := l_ztsv(i).value;
         end loop;
      end if;
      return l_results;
   end;

   overriding member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double
   is
   begin
      if p_ind_values.count != 1 then
         cwms_err.raise(
            'ERROR',
            'Rating '
            ||rating_spec_id
            ||' takes 1 independent parameter, '
            ||p_ind_values.count
            ||' specified');
      end if;
      return rate(p_ind_values(1));
   end;

   overriding member function rate(
      p_ind_value in binary_double)
   return binary_double
   is
      l_ztsv ztsv_type;
   begin
      l_ztsv := rate(ztsv_type(sysdate, p_ind_value, 0));
      return l_ztsv.value;
   end;

   overriding member function rate(
      p_ind_values in tsv_array)
   return tsv_array
   is
      l_results tsv_array;
      l_ztsv    ztsv_array;
      l_clone   stream_rating_t;
   begin
      if p_ind_values is not null then
         l_ztsv := ztsv_array();
         l_ztsv.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_ztsv(i).date_time    := cast(p_ind_values(i).date_time at time zone 'UTC' as date);
            l_ztsv(i).value        := p_ind_values(i).value;
            l_ztsv(i).quality_code := 0;
         end loop;
         if current_time = 'D' then
            l_ztsv := rate(l_ztsv);
         else
            l_clone := self;
            l_clone.convert_to_database_time;
            l_ztsv := l_clone.rate(l_ztsv);
         end if;
         l_results := tsv_array();
         l_results.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_results(i).date_time    := p_ind_values(i).date_time;
            l_results(i).value        := l_ztsv(i).value;
            l_results(i).quality_code := case l_results(i) is null
                                            when true  then 5
                                            when false then 0
                                         end;
         end loop;
      end if;
      return l_results;
   end;

   overriding member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array
   is
      type integer_tab_t is table of pls_integer;
      c_base_date               constant date := date '1900-01-01';
      l_results                 ztsv_array;
      l_date_offsets            double_tab_t;
      l_date_offset             binary_double;
      l_ratio                   binary_double;
      l_date_offsets_properties cwms_lookup.sequence_properties_t;
      l_shift                   binary_double;
      l_offset                  binary_double;
      l_heights                 double_tab_t;
      l_flows                   double_tab_t;
      l_height                  binary_double;
      l_heights_properties      cwms_lookup.sequence_properties_t;
      i                         pls_integer;
      j                         pls_integer;
      k                         pls_integer;
      l_hi_index                pls_integer;
      l_hi_value                binary_double;
      l_lo_value                binary_double;
      l_hi_height               binary_double;
      l_lo_height               binary_double;
      l_hi_flow                 binary_double;
      l_lo_flow                 binary_double;
      l_min_height              binary_double;
      l_log_used                boolean;
      l_rating_spec             rating_spec_t;
      l_rating_template         rating_template_t;
      l_rating_method           pls_integer;
      l_shift_count             pls_integer := 0;
   begin
      if p_ind_values is not null then
         -----------------------------
         -- get the rating template --
         -----------------------------
         l_rating_spec := rating_spec_t(rating_spec_id, office_id);
         l_rating_template := rating_template_t(office_id, l_rating_spec.template_id);
         -----------------------------------------
         -- populate the shift dates for lookup --
         -----------------------------------------
         if shifts is not null and shifts.count > 0 then
            l_shift_count  := shifts.count;
            l_date_offsets := double_tab_t();
            l_date_offsets.extend(shifts.count+1);
            l_date_offsets(1) := effective_date - c_base_date;
            for i in 1..shifts.count loop
               l_date_offsets(i+1) := shifts(i).effective_date - c_base_date;
            end loop;
            l_date_offsets_properties := cwms_lookup.analyze_sequence(l_date_offsets);
         end if;
         --------------------------------------------
         -- populate the rating heights for lookup --
         --------------------------------------------
         i := 1;
         j := 1;
         k := 0;
         l_heights := double_tab_t();
         l_flows   := double_tab_t();
         -------------------------------------------------
         -- first any extension values below the rating --
         -------------------------------------------------
         if rating_info.extension_values is not null then
            while i < rating_info.extension_values.count and
                  rating_info.extension_values(i).ind_value < rating_info.rating_values(1).ind_value
            loop
               l_heights.extend;
               l_flows.extend;
               k := k + 1;
               l_heights(k) := rating_info.extension_values(i).ind_value;
               l_flows(k) := rating_info.extension_values(i).dep_value;
            end loop;
         end if;
         ----------------------------
         -- next the rating values --
         ----------------------------
         while j < rating_info.rating_values.count loop
            l_heights.extend;
            l_flows.extend;
            k := k + 1;
            l_heights(k) := rating_info.rating_values(j).ind_value;
            l_flows(k) := rating_info.rating_values(j).dep_value;
            j := j + 1;
         end loop;
         ---------------------------------------------------
         -- finally any extension values above the rating --
         ---------------------------------------------------
         if rating_info.extension_values is not null then
            while i < rating_info.extension_values.count loop
               if rating_info.extension_values(i).ind_value >
                  rating_info.rating_values(rating_info.rating_values.count).ind_value
               then
                  l_heights.extend;
                  l_flows.extend;
                  k := k + 1;
                  l_heights(k) := rating_info.extension_values(i).ind_value;
                  l_flows(k) := rating_info.extension_values(i).dep_value;
               end if;
            end loop;
         end if;
         l_heights_properties := cwms_lookup.analyze_sequence(l_heights);
         -------------------------
         -- process each height --
         -------------------------
         l_results := ztsv_array();
         l_results.extend(p_ind_values.count);
         for i in 1..p_ind_values.count loop
            l_results(i) := ztsv_type(p_ind_values(i).date_time, null, 0);
            -----------------------------------
            -- shift the height if necessary --
            -----------------------------------
            l_height := p_ind_values(i).value;
            if l_shift_count > 0 and p_ind_values(i).date_time >= effective_date then
               l_date_offset := p_ind_values(i).date_time - c_base_date;
               l_hi_index := cwms_lookup.find_high_index(
                  l_date_offset,
                  l_date_offsets,
                  l_date_offsets_properties);
               l_ratio := cwms_lookup.find_ratio(
                  l_log_used,
                  l_date_offset,
                  l_date_offsets,
                  l_hi_index,
                  l_date_offsets_properties.increasing_range,
                  cwms_lookup.method_linear,
                  cwms_lookup.method_error,
                  cwms_lookup.method_nearest);
               if l_ratio != 0. then
                  l_hi_value := shifts(l_hi_index-1).rate(l_height);
               end if;
               if l_ratio != 1. then
                  if l_hi_index = 1 then
                     l_lo_value := 0.;
                  else
                     l_lo_value := shifts(l_hi_index).rate(l_height);
                  end if;
               end if;
               if l_ratio = 0. then
                  l_height := l_height + l_lo_value;
               elsif l_ratio = 1. then
                  l_height := l_height + l_hi_value;
               else
                  l_height := l_height + l_lo_value + l_ratio * (l_hi_value - l_lo_value);
               end if;
            end if;
            -----------------------------------
            -- find the interpolation values --
            -----------------------------------
            l_hi_index := cwms_lookup.find_high_index(
               l_height,
               l_heights,
               l_heights_properties);
            if l_height < l_heights(1) then
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).out_range_low_rating_method);
            elsif l_height > l_heights(l_heights.count) then
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).out_range_high_rating_method);
            else
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).in_range_rating_method);
            end if;
            if l_rating_method in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin) then
               if offsets is null then
                  l_offset := 0;
               else
                  l_min_height  := least(l_height, l_heights(l_hi_index-1));
                  if offsets.rating_info.rating_values.count = 1 then
                     l_offset := offsets.rating_info.rating_values(1).dep_value;
                  else
                     l_offset := offsets.rate(l_min_height);
                  end if;
               end if;
               l_lo_height := log(10, l_heights(l_hi_index-1) - l_offset);
               l_hi_height := log(10, l_heights(l_hi_index) - l_offset);
               if l_rating_method = cwms_lookup.method_logarithmic then
                  l_lo_flow   := log(10, l_flows(l_hi_index-1));
                  l_hi_flow   := log(10, l_flows(l_hi_index));
               end if;
               if l_lo_height is NaN or l_lo_height is Infinite or
                  l_hi_height is NaN or l_hi_height is Infinite or
                  l_lo_flow   is NaN or l_lo_flow   is Infinite or
                  l_hi_flow   is NaN or l_hi_flow   is Infinite
               then
                  l_lo_height := l_heights(l_hi_index-1);
                  l_hi_height := l_heights(l_hi_index);
                  l_lo_flow   := l_flows(l_hi_index-1);
                  l_hi_flow   := l_flows(l_hi_index);
                  l_log_used  := false;
               else
                  l_height    := log(10, l_height - l_offset);
                  l_log_used  := true;
               end if;
            elsif l_rating_method = cwms_lookup.method_lin_log then
               l_lo_height := l_heights(l_hi_index-1);
               l_hi_height := l_heights(l_hi_index);
               l_lo_flow   := log(10, l_flows(l_hi_index-1));
               l_hi_flow   := log(10, l_flows(l_hi_index));
               l_log_used  := true;
               if l_lo_flow is NaN or l_lo_flow is Infinite or
                  l_hi_flow is NaN or l_hi_flow is Infinite
               then
                  l_lo_flow   := l_flows(l_hi_index-1);
                  l_hi_flow   := l_flows(l_hi_index);
                  l_log_used  := false;
               end if;
            else
               l_lo_height := l_heights(l_hi_index-1);
               l_hi_height := l_heights(l_hi_index);
               l_lo_flow   := l_flows(l_hi_index-1);
               l_hi_flow   := l_flows(l_hi_index);
               l_log_used  := false;
            end if;
            -------------------------------
            -- perform the interpolation --
            -------------------------------
            if l_rating_method in (
               cwms_lookup.method_linear,
               cwms_lookup.method_logarithmic,
               cwms_lookup.method_lin_log,
               cwms_lookup.method_log_lin)
            then
               l_results(i).value :=
                  l_lo_flow
                  + (l_height - l_lo_height)
                  / (l_hi_height - l_lo_height)
                  * (l_hi_flow - l_lo_flow);
               if l_log_used then
                  l_results(i).value := power(10, l_results(i).value);
               end if;
            elsif l_rating_method = cwms_lookup.method_null then
               l_results(i).value := null;
            elsif l_rating_method = cwms_lookup.method_error then
               if l_height < l_lo_height then
                  cwms_err.raise(
                     'ERROR',
                     'Value is out of bounds low');
               elsif l_height > l_hi_height then
                  cwms_err.raise(
                     'ERROR',
                     'Value is out of bounds high');
               else
                  cwms_err.raise(
                     'ERROR',
                     'Value does not match any value in sequence');
               end if;
            elsif l_rating_method in (
               cwms_lookup.method_previous,
               cwms_lookup.method_lower)
            then
               if l_height < l_lo_height then
                  cwms_err.raise(
                     'ERROR',
                     'PREVIOUS or LOWER specified for out of bounds low behavior');
               end if;
               l_results(i).value := l_lo_flow;
            elsif l_rating_method in (
               cwms_lookup.method_next,
               cwms_lookup.method_higher)
            then
               if l_height > l_hi_height then
                  cwms_err.raise(
                     'ERROR',
                     'NEXT or HIGHER specified for out of bounds high behavior');
               end if;
               l_results(i).value := l_hi_flow;
            elsif l_rating_method in (
               cwms_lookup.method_nearest,
               cwms_lookup.method_closest)
            then
               if l_height < l_lo_height then
                  l_results(i).value := l_lo_flow;
               elsif l_height > l_hi_height then
                  l_results(i).value := l_hi_flow;
               else
                  if l_height - l_lo_height < l_hi_height - l_height then
                     l_results(i).value := l_lo_flow;
                  else
                     l_results(i).value := l_hi_flow;
                  end if;
               end if;
            else
               cwms_err.raise('ERROR', 'Invalid rating method');
            end if;
            if l_results(i).value is null then
               l_results(i).quality_code := 5;
            end if;
         end loop;
      end if;
      return l_results;
   end;

   overriding member function rate(
      p_ind_value in tsv_type)
   return tsv_type
   is
      l_results tsv_array;
   begin
      l_results := rate(tsv_array(p_ind_value));
      return l_results(1);
   end;

   overriding member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type
   is
      l_results ztsv_array;
   begin
      l_results := rate(ztsv_array(p_ind_value));
      return l_results(1);
   end;

   overriding member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t
   is
      l_results double_tab_t;
      l_ztsv    ztsv_array;
   begin
      if p_dep_values is not null then
         l_ztsv := ztsv_array();
         l_ztsv.extend(p_dep_values.count);
         for i in 1..p_dep_values.count loop
            l_ztsv(i).date_time := sysdate;
            l_ztsv(i).value     := p_dep_values(i);
         end loop;
         l_ztsv := reverse_rate(l_ztsv);
         l_results := double_tab_t();
         l_results.extend(p_dep_values.count);
         for i in 1..p_dep_values.count loop
            l_results(i) := l_ztsv(i).value;
         end loop;
      end if;
      return l_results;
   end;

   overriding member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double
   is
      l_ztsv ztsv_type;
   begin
      l_ztsv := reverse_rate(ztsv_type(sysdate, p_dep_value, 0));
      return l_ztsv.value;
   end;

   overriding member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array
   is
      l_results tsv_array;
      l_ztsv    ztsv_array;
      l_clone   stream_rating_t;
   begin
      if p_dep_values is not null then
         l_ztsv := ztsv_array();
         l_ztsv.extend(p_dep_values.count);
         for i in 1..p_dep_values.count loop
            l_ztsv(i).date_time    := cast(p_dep_values(i).date_time at time zone 'UTC' as date);
            l_ztsv(i).value        := p_dep_values(i).value;
            l_ztsv(i).quality_code := 0;
         end loop;
         if current_time = 'D' then
            l_ztsv := reverse_rate(l_ztsv);
         else
            l_clone := self;
            l_clone.convert_to_database_time;
            l_ztsv := l_clone.reverse_rate(l_ztsv);
         end if;
         l_results := tsv_array();
         l_results.extend(p_dep_values.count);
         for i in 1..p_dep_values.count loop
            l_results(i).date_time    := p_dep_values(i).date_time;
            l_results(i).value        := l_ztsv(i).value;
            l_results(i).quality_code := case l_results(i) is null
                                            when true  then 5
                                            when false then 0
                                         end;
         end loop;
      end if;
      return l_results;
   end;

   overriding member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array
   is
      type integer_tab_t is table of pls_integer;
      c_base_date               constant date := date '1900-01-01';
      l_results                 ztsv_array;
      l_date_offsets            double_tab_t;
      l_date_offset             binary_double;
      l_ratio                   binary_double;
      l_date_offsets_properties cwms_lookup.sequence_properties_t;
      l_shift                   binary_double;
      l_offset                  binary_double;
      l_heights                 double_tab_t;
      l_flows                   double_tab_t;
      l_shifts                  double_tab_t;
      l_flow                    binary_double;
      l_flows_properties        cwms_lookup.sequence_properties_t;
      i                         pls_integer;
      j                         pls_integer;
      k                         pls_integer;
      l_hi_index                pls_integer;
      l_hi_value                binary_double;
      l_lo_value                binary_double;
      l_hi_height               binary_double;
      l_lo_height               binary_double;
      l_hi_flow                 binary_double;
      l_lo_flow                 binary_double;
      l_min_height              binary_double;
      l_log_used                boolean;
      l_rating_spec             rating_spec_t;
      l_rating_template         rating_template_t;
      l_rating_method           pls_integer;
   begin
      if p_dep_values is not null then
         -----------------------------
         -- get the rating template --
         -----------------------------
         l_rating_spec := rating_spec_t(rating_spec_id, office_id);
         l_rating_template := rating_template_t(office_id, l_rating_spec.template_id);
         -----------------------------------------
         -- populate the shift dates for lookup --
         -----------------------------------------
         if shifts is not null then
            l_date_offsets := double_tab_t();
            l_date_offsets.extend(shifts.count+1);
            l_date_offsets(1) := effective_date - c_base_date;
            for i in 1..shifts.count loop
               l_date_offsets(i+1) := shifts(i).effective_date - c_base_date;
            end loop;
            l_date_offsets_properties := cwms_lookup.analyze_sequence(l_date_offsets);
         end if;
         ------------------------------------------------------
         -- populate the rating heights and flows for lookup --
         ------------------------------------------------------
         i := 1;
         j := 1;
         k := 0;
         l_heights := double_tab_t();
         l_flows   := double_tab_t();
         -------------------------------------------------
         -- first any extension values below the rating --
         -------------------------------------------------
         if rating_info.extension_values is not null then
            while i < rating_info.extension_values.count and
                  rating_info.extension_values(i).ind_value < rating_info.rating_values(1).ind_value
            loop
               l_heights.extend;
               l_flows.extend;
               k := k + 1;
               l_heights(k) := rating_info.extension_values(i).ind_value;
               l_flows(k) := rating_info.extension_values(i).dep_value;
            end loop;
         end if;
         ----------------------------
         -- next the rating values --
         ----------------------------
         while j < rating_info.rating_values.count loop
            l_heights.extend;
            l_flows.extend;
            k := k + 1;
            l_heights(k) := rating_info.rating_values(j).ind_value;
            l_flows(k) := rating_info.rating_values(j).dep_value;
            j := j + 1;
         end loop;
         ---------------------------------------------------
         -- finally any extension values above the rating --
         ---------------------------------------------------
         if rating_info.extension_values is not null then
            while i < rating_info.extension_values.count loop
               if rating_info.extension_values(i).ind_value >
                  rating_info.rating_values(rating_info.rating_values.count).ind_value
               then
                  l_heights.extend;
                  l_flows.extend;
                  k := k + 1;
                  l_heights(k) := rating_info.extension_values(i).ind_value;
                  l_flows(k) := rating_info.extension_values(i).dep_value;
               end if;
            end loop;
         end if;
         l_flows_properties := cwms_lookup.analyze_sequence(l_flows);
         -----------------------
         -- process each flow --
         -----------------------
         l_results := ztsv_array();
         l_results.extend(p_dep_values.count);
         for i in 1..p_dep_values.count loop
            l_results(i) := ztsv_type(p_dep_values(i).date_time, null, 0);
            l_flow := p_dep_values(i).value;
            -----------------------------------
            -- find the interpolation values --
            -----------------------------------
            l_hi_index := cwms_lookup.find_high_index(
               l_flow,
               l_flows,
               l_flows_properties);
            l_lo_height := l_heights(l_hi_index-1);
            l_hi_height := l_heights(l_hi_index);
            l_lo_flow   := l_flows(l_hi_index-1);
            l_hi_flow   := l_flows(l_hi_index);
            l_log_used  := false;
            if l_flow < l_flows(1) then
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).out_range_low_rating_method);
            elsif l_flow > l_flows(l_flows.count) then
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).out_range_high_rating_method);
            else
               l_rating_method := cwms_lookup.method_by_name(l_rating_template.ind_parameters(1).in_range_rating_method);
            end if;
            if l_rating_method in (cwms_lookup.method_logarithmic, cwms_lookup.method_log_lin) then
               if offsets is null then
                  l_offset := 0;
               else
                  if offsets.rating_info.rating_values.count = 1 then
                     l_offset := offsets.rating_info.rating_values(1).dep_value;
                  else
                     l_offset := offsets.rate(l_heights(l_hi_index-1));
                  end if;
               end if;
               if l_rating_method = cwms_lookup.method_logarithmic then
                  if l_flow > 0 then
                     l_lo_height := log(10, l_heights(l_hi_index-1) - l_offset);
                     l_hi_height := log(10, l_heights(l_hi_index) - l_offset);
                     l_log_used  := true;
                     l_lo_flow := log(10, l_flows(l_hi_index-1));
                     l_hi_flow := log(10, l_flows(l_hi_index));
                     if l_lo_height is NaN or l_lo_height is Infinite or
                        l_lo_height is NaN or l_lo_height is Infinite or
                        l_lo_flow   is NaN or l_lo_flow   is Infinite or
                        l_lo_flow   is NaN or l_lo_flow   is Infinite
                     then
                        l_lo_height := l_heights(l_hi_index-1);
                        l_hi_height := l_heights(l_hi_index);
                        l_lo_flow   := l_flows(l_hi_index-1);
                        l_hi_flow   := l_flows(l_hi_index);
                        l_log_used  := false;
                     else
                        l_flow := log(10, l_flow);
                     end if;
                  end if;
               end if;
            elsif l_rating_method = cwms_lookup.method_lin_log then
               l_lo_height := l_heights(l_hi_index-1);
               l_hi_height := l_heights(l_hi_index);
               l_log_used  := false;
               if l_flow > 0 then
                  l_lo_flow := log(10, l_flows(l_hi_index-1));
                  l_hi_flow := log(10, l_flows(l_hi_index));
                  if l_lo_flow   is NaN or l_lo_flow   is Infinite or
                     l_lo_flow   is NaN or l_lo_flow   is Infinite
                  then
                     l_lo_flow   := l_flows(l_hi_index-1);
                     l_hi_flow   := l_flows(l_hi_index);
                  else
                     l_flow := log(10, l_flow);
                  end if;
               end if;
            else
               l_lo_height := l_heights(l_hi_index-1);
               l_hi_height := l_heights(l_hi_index);
               l_lo_flow   := l_flows(l_hi_index-1);
               l_hi_flow   := l_flows(l_hi_index);
               l_log_used  := false;
            end if;
            -------------------------------
            -- perform the interpolation --
            -------------------------------
            if l_rating_method in (
               cwms_lookup.method_linear,
               cwms_lookup.method_logarithmic,
               cwms_lookup.method_lin_log,
               cwms_lookup.method_log_lin)
            then
               l_results(i).value :=
                  l_lo_height
                  + (l_flow - l_lo_flow)
                  / (l_hi_flow - l_lo_flow)
                  * (l_hi_height - l_lo_height);
               if l_log_used then
                  l_results(i).value := power(10, l_results(i).value) + l_offset;
               end if;
               -------------------------------------
               -- unshift the height if necessary --
               -------------------------------------
               if shifts is not null and shifts.count > 0 and p_dep_values(i).date_time >= effective_date then
                  l_date_offset := p_dep_values(i).date_time - c_base_date;
                  l_hi_index := cwms_lookup.find_high_index(
                     l_date_offset,
                     l_date_offsets,
                     l_date_offsets_properties);
                  l_ratio := cwms_lookup.find_ratio(
                     l_log_used,
                     l_date_offset,
                     l_date_offsets,
                     l_hi_index,
                     l_date_offsets_properties.increasing_range,
                     cwms_lookup.method_linear,
                     cwms_lookup.method_error,
                     cwms_lookup.method_nearest);
                  if l_ratio != 0. then
                     l_heights.delete;
                     l_heights.extend(shifts(l_hi_index-1).rating_info.rating_values.count);
                     l_shifts := double_tab_t();
                     l_shifts.extend(shifts(l_hi_index-1).rating_info.rating_values.count);
                     for j in 1..shifts(l_hi_index-1).rating_info.rating_values.count loop
                        l_heights(j) := shifts(l_hi_index-1).rating_info.rating_values(j).ind_value;
                        l_shifts(j) := shifts(l_hi_index-1).rating_info.rating_values(j).dep_value;
                     end loop;
                     if l_results(i).value - l_shifts(1) <= l_heights(1) then
                        l_hi_value := l_shifts(1);
                     elsif l_results(i).value - l_shifts(l_shifts.count) >= l_heights(l_heights.count) then
                        l_hi_value := l_shifts(l_shifts.count);
                     else
                        for j in 2..l_shifts.count loop
                           if l_results(i).value - l_shifts(j) <= l_heights(j) then
                              declare
                                 k    pls_integer   := case j = l_shifts.count when true then j-1 else j end;
                                 s0   binary_double := l_shifts(k);
                                 s1   binary_double := l_shifts(k+1);
                                 h0   binary_double := l_heights(k);
                                 h1   binary_double := l_heights(k+1);
                                 hs   binary_double := l_results(i).value;
                                 dsdh binary_double := (s1-s0)/(h1-h0);
                              begin
                                 l_hi_value := hs-(hs-s0+h0*dsdh)/(1+dsdh);
                              end;
                              exit;
                           end if;
                        end loop;
                     end if;
                  end if;
                  if l_ratio != 1. then
                     if l_hi_index = 1 then
                        l_lo_value := 0.; -- zero shift on base curve
                     else
                        l_heights.delete;
                        l_heights.extend(shifts(l_hi_index).rating_info.rating_values.count);
                        l_shifts := double_tab_t();
                        l_shifts.extend(shifts(l_hi_index).rating_info.rating_values.count);
                        for j in 1..shifts(l_hi_index).rating_info.rating_values.count loop
                           l_heights(j) := shifts(l_hi_index).rating_info.rating_values(j).ind_value;
                           l_shifts(j) := shifts(l_hi_index).rating_info.rating_values(j).dep_value;
                        end loop;
                        if l_results(i).value - l_shifts(1) <= l_heights(1) then
                           l_lo_value := l_shifts(1);
                        elsif l_results(i).value - l_shifts(l_shifts.count) >= l_heights(l_heights.count) then
                           l_lo_value := l_shifts(l_shifts.count);
                        else
                           for j in 2..l_shifts.count loop
                              if l_results(i).value - l_shifts(j) <= l_heights(j) then
                                 declare
                                 k    pls_integer   := case j = l_shifts.count when true then j-1 else j end;
                                 s0   binary_double := l_shifts(k);
                                 s1   binary_double := l_shifts(k+1);
                                 h0   binary_double := l_heights(k);
                                 h1   binary_double := l_heights(k+1);
                                 hs   binary_double := l_results(i).value;
                                 dsdh binary_double := (s1-s0)/(h1-h0);
                                 begin
                                    l_lo_value := hs-(hs-s0+h0*dsdh)/(1+dsdh);
                                 end;
                                 exit;
                              end if;
                           end loop;
                        end if;
                     end if;
                  end if;
                  if l_ratio = 0. then
                     l_shift := l_lo_value;
                  elsif l_ratio = 1. then
                     l_shift := l_hi_value;
                  else
                     l_shift := l_lo_value + l_ratio * (l_hi_value - l_lo_value);
                  end if;
                  l_results(i).value := l_results(i).value - l_shift;
               end if;
            elsif l_rating_method = cwms_lookup.method_null then
               l_results(i).value := null;
            elsif l_rating_method = cwms_lookup.method_error then
               if l_flow < l_lo_flow then
                  cwms_err.raise(
                     'ERROR',
                     'Value is out of bounds low');
               elsif l_flow > l_hi_flow then
                  cwms_err.raise(
                     'ERROR',
                     'Value is out of bounds high');
               else
                  cwms_err.raise(
                     'ERROR',
                     'Value does not match any value in sequence');
               end if;
            elsif l_rating_method in (
               cwms_lookup.method_previous,
               cwms_lookup.method_lower)
            then
               if l_flow < l_lo_flow then
                  cwms_err.raise(
                     'ERROR',
                     'PREVIOUS or LOWER specified for out of bounds low behavior');
               end if;
               l_results(i).value := l_lo_height;
            elsif l_rating_method in (
               cwms_lookup.method_next,
               cwms_lookup.method_higher)
            then
               if l_flow > l_hi_flow then
                  cwms_err.raise(
                     'ERROR',
                     'NEXT or HIGHER specified for out of bounds high behavior');
               end if;
               l_results(i).value := l_hi_height;
            elsif l_rating_method in (
               cwms_lookup.method_nearest,
               cwms_lookup.method_closest)
            then
               if l_flow < l_lo_flow then
                  l_results(i).value := l_lo_height;
               elsif l_flow > l_hi_flow then
                  l_results(i).value := l_hi_height;
               else
                  if l_flow - l_lo_flow < l_hi_flow - l_flow then
                     l_results(i).value := l_lo_height;
                  else
                     l_results(i).value := l_hi_height;
                  end if;
               end if;
            else
               cwms_err.raise('ERROR', 'Invalid rating method');
            end if;
            l_results(i).date_time := p_dep_values(i).date_time;
            l_results(i).quality_code := case l_results(i).value is null
                                          when true  then 5
                                          when false then 0
                                       end;

         end loop;
      end if;
      return l_results;
   end;

   overriding member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type
   is
      l_results tsv_array;
   begin
      l_results := reverse_rate(tsv_array(p_dep_value));
      return l_results(1);
   end;

   overriding member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type
   is
      l_results ztsv_array;
   begin
      l_results := reverse_rate(ztsv_array(p_dep_value));
      return l_results(1);
   end;

   member procedure trim_to_effective_date(
      p_date_time in date)
   is
   begin
      if shifts is not null then
         for i in reverse 1..shifts.count loop
            exit when shifts(i).effective_date < p_date_time;
            shifts.trim(1);
         end loop;
         if shifts.count = 0 then
            shifts := null;
         end if;
      end if;
   end;

   member procedure trim_to_create_date(
      p_date_time in date)
   is
      l_count  pls_integer := 0;
      l_shifts rating_tab_t;
   begin
      if shifts is not null then
         for i in 1..shifts.count loop
            if shifts(i).create_date > p_date_time then
               l_count := l_count + 1;
            end if;
         end loop;
         if l_count > 0 then
            if l_count < shifts.count then
               l_shifts := rating_tab_t();
               for i in 1..shifts.count loop
                  if shifts(i).create_date <= p_date_time then
                     l_shifts.extend;
                     l_shifts(l_shifts.count) := shifts(i);
                  end if;
               end loop;
            end if;
            shifts := l_shifts;
         end if;
      end if;
   end;

   member function latest_shift_date
   return date
   is
   begin
      return case shifts is null or shifts.count = 0
                when true  then null
                when false then shifts(shifts.count).effective_date
             end;
   end;
end;
/

show errors;

commit;
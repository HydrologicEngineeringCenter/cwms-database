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
      p_fail_if_exists in varchar2)
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
      return;         
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
   
   member procedure init(
      p_template_code in number),
   
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2),
      
   member function get_office_code
   return number,
   
   member function get_dep_parameter_code
   return number,
   
   member procedure store(
      p_fail_if_exists in varchar2),
      
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
            l_office_id number(10);
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
   
   member procedure init(
      p_rating_spec_code in number),
      
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null),
            
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
      select lg.loc_group_code
        into l_source_agency_code
        from at_loc_group lg,
             at_loc_category lc
       where lc.loc_category_id = 'Agency Aliases'
         and lg.loc_category_code = lc.loc_category_code
         and lg.db_office_code in (get_location_code, cwms_util.db_office_code_all)
         and upper(lg.loc_group_id) = upper(self.source_agency_id);
         
      return l_source_agency_code;         
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
   parameter_position number(1)
) not final
  not instantiable;
/
show errors;

create type rating_value_t as object(
   ind_value            binary_double,
   dep_value            binary_double,
   dep_rating_ind_param abs_rating_ind_parameter_t,
   note_id              varchar2(16),
   
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
-- parameter_position number(1),
   rating_values      rating_value_tab_t,
   extension_values   rating_value_tab_t,
   
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number)
   return self as result,
   
   constructor function rating_ind_parameter_t(
      p_rating_code         in number,
      p_ind_param_spec_code in number)
   return self as result,
   
   member procedure init(
      p_rating_ind_parameter_code in number),
      
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2),
      
   member procedure store(
      p_rating_code           in  number,
      p_parameter_position    in  number,
      p_fail_if_exists        in  varchar2)
);
/
show errors;

create type body rating_ind_parameter_t
as
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number)
   return self as result
   is
   begin
      init(p_rating_ind_parameter_code);
      return;
   end;
   
   constructor function rating_ind_parameter_t(
      p_rating_code         in number,
      p_ind_param_spec_code in number)
   return self as result
   is
      l_rating_ind_param_code number;
   begin
      select rating_ind_param_code
        into l_rating_ind_param_code
        from at_rating_ind_parameter
       where rating_code = p_rating_code
         and ind_param_spec_code = p_ind_param_spec_code;
         
      init(l_rating_ind_param_code);
      return;
   end;
   
   member procedure init(
      p_rating_ind_parameter_code in number)
   is
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
         select parameter_position
           into self.parameter_position
           from at_rating_ind_param_spec
          where ind_param_spec_code = rec.ind_param_spec_code;
          
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
         select lips.ind_param_spec_code
           into l_rec.ind_param_spec_code
           from at_rating l,
                at_rating_spec ls,
                at_rating_ind_param_spec lips
          where l.rating_code = p_rating_code
            and ls.rating_spec_code = l.rating_spec_code
            and lips.template_code = ls.template_code
            and lips.parameter_position = p_parameter_position; 
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
        from at_rating l,
             at_rating_spec ls,
             at_rating_template lt,
             cwms_office co
       where l.rating_code = p_rating_code
         and ls.rating_spec_code = l.rating_spec_code
         and lt.template_code = ls.template_code
         and co.office_code = lt.office_code;    
      
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
      
end;
/
show errors;

create type rating_ind_parameter_tab_t as table of rating_ind_parameter_t;
/
show errors;

create type body rating_value_t
as
   
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
         l_rec.note_code := l_note_rec.note_code;               
      end if;
      if self.dep_rating_ind_param is not null then
         l_rating_ind_parameter := treat(self.dep_rating_ind_param as rating_ind_parameter_t);
         select rating_code
           into l_rating_code
           from at_rating_ind_parameter
          where rating_ind_param_code = p_rating_ind_param_code;
          l_rating_ind_parameter.store(
             p_rating_ind_param_code => l_rec.dep_rating_ind_param_code,
             p_rating_code           => l_rating_code,
             p_parameter_position    => self.dep_rating_ind_param.parameter_position,
             p_fail_if_exists        => 'T');
      end if;
      l_rec.rating_ind_param_code := p_rating_ind_param_code;
      l_rec.ind_value := self.ind_value;
      l_rec.dep_value := self.dep_value;
      
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
   rating_id      varchar2(372),
   effective_date date,
   create_date    date,
   active_flag    varchar2(1),
   formula        varchar2(1000),
   description    varchar2(256),
   ind_parameters rating_ind_parameter_tab_t,
   
   constructor function rating_t(
      p_rating_code in number)
   return self as result,
   
   constructor function rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
      
   member procedure init(
      p_rating_code in number),
   
   member procedure init(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null),
      
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2),
   
   member procedure store(
      p_fail_if_exists in varchar2),
      
   static function get_rating_code(         
      p_rating_id      in varchar2,
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
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result
   is
   begin
      init(
         p_rating_id,
         p_effective_date,
         p_match_date,
         p_time_zone,
         p_office_id);
         
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
                
               self.rating_id := 
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
         self.description    := rec.description;
         self.ind_parameters := rating_ind_parameter_tab_t();
         self.ind_parameters.extend(l_ind_param_count);
         for i in 1..l_ind_param_count loop
            self.ind_parameters(i) := rating_ind_parameter_t(
               p_rating_code, 
               l_ind_param_spec_codes(i));
         end loop;              
      end loop;
   end;      
   
   member procedure init(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   is
      l_rating_code number(10);
   begin
      l_rating_code := rating_t.get_rating_code(
         p_rating_id,
         p_effective_date,
         p_match_date,
         p_time_zone,
         p_office_id);
         
      init(l_rating_code);
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
         self.rating_id,
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
               ||self.rating_id
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
      
      if ind_parameters is not null then
         for i in 1..ind_parameters.count loop
            ind_parameters(i).store(l_rec.rating_code, i, 'F');
         end loop;
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
      
   static function get_rating_code(         
      p_rating_id      in varchar2,
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
      l_parts := cwms_util.split_text(p_rating_id, '.');
      if l_parts.count != 4 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_rating_id,
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
               l_office_id||'/'||p_rating_id);
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
-- ind_parameters rating_ind_parameter_tab_t,
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


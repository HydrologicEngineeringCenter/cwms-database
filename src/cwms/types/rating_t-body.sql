create or replace type body rating_t
as
   constructor function rating_t(
      p_rating_spec_id  varchar2,
      p_native_units    varchar2,
      p_effective_date  date,
      p_active_flag     varchar2,
      p_formula         varchar2,
      p_rating_info     rating_ind_parameter_t,
      p_description     varchar2,
      p_office_id       varchar2 default null)
      return self as result
   is
   begin
      self.rating_spec_id := p_rating_spec_id;
      self.native_units   := p_native_units;
      self.effective_date := trunc(p_effective_date, 'MI');
      self.active_flag    := p_active_flag;
      self.formula        := p_formula;
      self.rating_info    := p_rating_info;
      self.description    := p_description;
      self.office_id      := cwms_util.get_db_office_id(p_office_id);
      self.create_date    := trunc(sysdate, 'MI');
      self.current_units  := 'N';
      self.current_time   := 'D';
      return;
   end;      

   constructor function rating_t(
      p_rating_spec_id  varchar2,
      p_native_units    varchar2,
      p_effective_date  date,
      p_transition_date date,
      p_active_flag     varchar2,
      p_formula         varchar2,
      p_rating_info     rating_ind_parameter_t,
      p_description     varchar2,
      p_office_id       varchar2 default null)
      return self as result
   is
   begin
      self.rating_spec_id  := p_rating_spec_id;
      self.native_units    := p_native_units;
      self.effective_date  := trunc(p_effective_date, 'MI');
      self.transition_date := trunc(p_transition_date, 'MI');
      self.active_flag     := p_active_flag;
      self.formula         := p_formula;
      self.rating_info     := p_rating_info;
      self.description     := p_description;
      self.office_id       := cwms_util.get_db_office_id(p_office_id);
      self.create_date     := trunc(sysdate, 'MI');
      self.current_units   := 'N';
      self.current_time    := 'D';
      return;
   end;

   constructor function rating_t(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
   return self as result
   is
   begin
      init(p_rating_code, p_include_points);
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
      l_xml                  xmltype;
      l_text                 varchar2(64);
      l_elev_positions       number_tab_t;
      l_datum                varchar2(16);
      l_is_virtual           boolean;
      l_is_transitional      boolean;
      l_source_ratings_xml   xmltype;
      l_select_xml           xmltype;
      l_position             binary_integer;
      l_is_rating            boolean;
      l_rating_part          varchar2(500);
      l_units_part           varchar2(50);
      l_xml_tab              xml_tab_t;
      l_xml_tab2             xml_tab_t;
      ------------------------------
      -- local function shortcuts --
      ------------------------------
      function get_node(pp_xml in xmltype, p_path in varchar2) return xmltype is
      begin
         return cwms_util.get_xml_node(pp_xml, p_path);
      end;
      function get_nodes(
         pp_xml       in xmltype,
         p_path       in varchar2,
         p_condition  in varchar2 default null,
         p_order_by   in varchar2 default null,
         p_descending in varchar2 default 'F')
      return xml_tab_t is
      begin
         return cwms_util.get_xml_nodes(pp_xml, p_path, p_condition, p_order_by, p_descending);
      end;
      function get_text(pp_xml in xmltype, p_path in varchar2) return varchar2 is
      begin
         return cwms_util.get_xml_text(pp_xml, p_path);
      end;
      function get_number(pp_xml in xmltype, p_path in varchar2) return number is
      begin
         return cwms_util.get_xml_number(pp_xml, p_path);
      end;
   begin
      l_xml := get_node(p_xml, '//rating|//simple-rating|//virtual-rating|//transitional-rating');
      if l_xml is null then
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating> element');
      end if;
      self.office_id := get_text(l_xml, '/*/@office-id');
      if self.office_id is null then
         cwms_err.raise('ERROR', 'Required office-id attribute not found');
      end if;
      self.rating_spec_id := get_text(l_xml, '/*/rating-spec-id');
      if self.rating_spec_id is null then
         cwms_err.raise('ERROR', 'Required <rating-spec-id> element not found');
      end if;
      ---------------------------------------------
      -- test for virtual or transitional rating --
      ---------------------------------------------
      l_is_virtual := get_node(l_xml, '/*/connections') is not null;
         if l_is_virtual then
         if l_xml.getrootelement != 'virtual-rating' then
            cwms_err.raise('ERROR', 'Cannot specify <connections> in <'||l_xml.getrootelement||'> element');
         end if;
         l_source_ratings_xml := get_node(l_xml, '/*/source-ratings');
         if l_source_ratings_xml is null then
            cwms_err.raise('ERROR', 'Required <source-ratings> not found under <virtual-rating> element');
         end if;
      else
         if l_xml.getrootelement = 'virtual-rating' then
            cwms_err.raise('ERROR', 'Required <connections> not found under <virtual-rating> element');
         end if;
      end if;
      l_select_xml := get_node(l_xml, '/*/select');
      l_is_transitional := l_select_xml is not null;
      if l_is_transitional then
         if l_xml.getrootelement != 'transitional-rating' then
            cwms_err.raise('ERROR', 'Cannot specify <select> in <'||l_xml.getrootelement||'> element');
         end if;
         l_source_ratings_xml := get_node(l_xml, '/*/source-ratings');
      else
         if l_xml.getrootelement = 'transitional-rating' then
            cwms_err.raise('ERROR', 'Required <select> not found under <transitional-rating> element');
         end if;
      end if;
      l_text := get_text(l_xml, '/*/effective-date');
      if l_text is null  then
            cwms_err.raise(
               'ERROR',
            'Required <effective-date> element not found on rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         self.effective_date := get_date(l_text);
      l_text := get_text(l_xml, '/*/transition-start-date');
      if l_text is not null then
         self.transition_date := get_date(l_text);
      end if;
      l_text := get_text(l_xml, '/*/create-date');
      if l_text is not null then
         self.create_date := get_date(l_text);
      end if;
      l_text := get_text(l_xml, '/*/active');
      if l_text is null then
         cwms_err.raise(
            'ERROR',
            'Missing <active> element under <'
            ||l_xml.getrootelement
            ||'> element on rating '
            ||self.office_id
            ||'/'
            ||self.rating_spec_id);
      else
         case l_text
            when 'true'  then self.active_flag := 'T';
            when '1'     then self.active_flag := 'T';
            when 'false' then self.active_flag := 'F';
            when '0'     then self.active_flag := 'F';
            else
               cwms_err.raise(
                  'ERROR',
                  'Invalid value for <active> element under <'
                  ||l_xml.getrootelement
                  ||'> element: '
                  ||l_text
                  ||', should be 1, 0, true or false on rating '
                  ||self.office_id
                  ||'/'
                  ||self.rating_spec_id);
         end case;
      end if;
      self.formula := get_text(l_xml, '/*/formula');
      if self.formula is not null then
         if l_is_virtual or l_is_transitional then
            cwms_err.raise(
               'ERROR',
               'Cannot specify <formula> element on virtual or transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         self.formula := regexp_replace(self.formula, '(?i|\$)(\d+)', 'arg\2', 1, 0, 'i');
      end if;
      if get_node(l_xml, '/*/rating-points') is not null then
         if l_is_virtual or l_is_transitional then
            cwms_err.raise(
               'ERROR',
               'Cannot specify <rating-points> element on virtual or transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         self.rating_info := rating_ind_parameter_t(l_xml);
      end if;
      self.native_units := get_text(l_xml, '/*/units-id');
      if self.native_units is null then
         if not l_is_virtual then
            cwms_err.raise(
               'ERROR',
               'Required <units-id> element not found on simple (table or expression) or transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
      else
         if l_is_virtual then
            cwms_err.raise(
               'ERROR',
               'Cannot specify <units-id> element on virtual rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
      end if;
      self.description := get_text(l_xml, '/*/description');
      if l_is_virtual then
         --------------------
         -- virtual rating --
         --------------------
         self.connections := get_text(l_xml, '/*/connections');
         if self.connections is null then
            cwms_err.raise(
               'ERROR',
               'Required <connections> element not found on virtual rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         l_xml_tab := get_nodes(
            l_source_ratings_xml,
            '/source-ratings/source-rating',
            null,
            '/source-ratings/source-rating/@position');
         self.source_ratings := str_tab_t();
         self.source_ratings.extend(l_xml_tab.count);
         for i in 1..l_xml_tab.count loop
            l_text := get_text(l_xml_tab(i), '/source-rating/@position');
            if l_text is null then
               cwms_err.raise(
                  'ERROR',
                  'Required position attribute not found on source rating of virtual rating '
                  ||self.office_id
                  ||'/'
                  ||self.rating_spec_id);
            end if;
            begin
               l_position := to_number(l_text);
            exception
               when others then
                  cwms_err.raise(
                     'ERROR',
                     'Invalid position attribute "'
                     ||l_text
                     ||'" found on source rating  of virtual rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
            end;
            if l_position != i then
               if i = 1 then
               cwms_err.raise(
                  'ERROR',
                     'Source rating positions must start at 1, got '
                     ||l_position
                  ||' on virtual rating '
                  ||self.office_id
                  ||'/'
                  ||self.rating_spec_id);
               else
                  if l_position < i then
                     cwms_err.raise(
                        'ERROR',
                        'Duplicate source rating positions of '
                        ||l_position
                        ||' found on virtual rating '
                        ||self.office_id
                        ||'/'
                        ||self.rating_spec_id);
                  else
                     cwms_err.raise(
                        'ERROR',
                        'Source rating position of '
                        ||i
                        ||' skipped on virtual rating '
                        ||self.office_id
                        ||'/'
                        ||self.rating_spec_id);
            end if;
               end if;
            end if;
            l_text := get_text(l_xml_tab(i), '/source-rating/rating-spec-id');
            if l_text is null then
               l_text := get_text(l_xml_tab(i), '/source-rating/rating-expression');
               if l_text is null then
                  cwms_err.raise(
                     'ERROR',
                     'Required <rating-spec-id> or <rating-expression> element not found on source rating '
                     ||i
                     ||' of virtual rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               end if;
            end if;
            parse_source_rating(l_is_rating, l_rating_part, l_units_part, l_text);
            if l_units_part is null then
               cwms_err.raise(
                  'ERROR',
                  'No units specified on source rating '
                  ||i
                  ||' of virtual rating '
                  ||self.office_id
                  ||'/'
                  ||self.rating_spec_id);
            end if;
            self.source_ratings(i) := l_text;
          end loop;
      elsif l_is_transitional then
         -------------------------
         -- transitional rating --
         -------------------------
         l_xml_tab := get_nodes(l_xml, '/transitional-rating/select');
         if l_xml_tab is null or l_xml_tab.count = 0 then
            cwms_err.raise(
               'ERROR',
               'Required <select> element not found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         elsif l_xml_tab.count > 1 then
            cwms_err.raise(
               'ERROR',
               'Multiple <select> elements found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         l_select_xml := l_xml_tab(1);
         l_xml_tab := get_nodes(l_xml, '/transitional-rating/source-ratings');
         if l_xml_tab is null or l_xml_tab.count = 0 then
            cwms_err.raise(
               'ERROR',
               'Required <source-ratings> element not found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         elsif l_xml_tab.count > 1 then
            cwms_err.raise(
               'ERROR',
               'Multiple <source-ratings> elements found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         l_source_ratings_xml := l_xml_tab(1);
         l_xml_tab := get_nodes(l_source_ratings_xml, '/source-ratings/rating-spec-id', null, '/source-ratings/rating-spec-id/@position');
         self.source_ratings := str_tab_t();
         self.source_ratings.extend(l_xml_tab.count);
         for i in 1..l_xml_tab.count loop
            self.source_ratings(i) := get_text(l_xml_tab(i), '/rating-spec-id');
         end loop;
         l_xml_tab := get_nodes(l_select_xml, '/select/case', null, '/select/case/@position');
         if l_xml_tab is null then
            self.evaluations := str_tab_tab_t();
            self.evaluations.extend(1);
         else
            self.conditions := logic_expr_tab_t();
            self.conditions.extend(l_xml_tab.count);
            self.evaluations := str_tab_tab_t();
            self.evaluations.extend(l_xml_tab.count+1);
            for i in 1..l_xml_tab.count loop
               l_text := get_text(l_xml_tab(i), '/case/@position');
               if l_text is null then
                  cwms_err.raise(
                     'ERROR',
                     'Required position attribute not found on <case> element of transitional rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               end if;
               begin
                  l_position := to_number(l_text);
               exception
                  when others then
                     cwms_err.raise(
                        'ERROR',
                        'Invalid position attribute "'
                        ||l_text
                        ||'" found on <case> element of transitional rating '
                        ||self.office_id
                        ||'/'
                        ||self.rating_spec_id);
               end;
               if l_position != i then
                  if i = 1 then
                     cwms_err.raise(
                        'ERROR',
                        'Case positions must start at 1, got '
                        ||l_position
                        ||' on transitional rating '
                        ||self.office_id
                        ||'/'
                        ||self.rating_spec_id);
                  else
                     if l_position < i then
                        cwms_err.raise(
                           'ERROR',
                           'Duplicate case positions of '
                           ||l_position
                           ||' found on transitional rating '
                           ||self.office_id
                           ||'/'
                           ||self.rating_spec_id);
                     else
                        cwms_err.raise(
                           'ERROR',
                           'Case position of '
                           ||i
                           ||' skipped on transitional rating '
                           ||self.office_id
                           ||'/'
                           ||self.rating_spec_id);
                     end if;
                  end if;
               end if;
               l_xml_tab2 := get_nodes(l_xml_tab(i), '/case/when');
               if l_xml_tab2 is null or l_xml_tab2.count = 0 then
                  cwms_err.raise(
                     'ERROR',
                     'Required <when> element not found in case '
                     ||i
                     ||' on transitional rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               elsif l_xml_tab2.count > 1 then
                  cwms_err.raise(
                     'ERROR',
                     'Multiple <when> elements found in case '
                     ||i
                     ||' on transitional rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               end if;
               self.conditions(i) := logic_expr_t(regexp_replace(
                                        regexp_replace(
                                           upper(get_text(l_xml_tab2(1), '/when')),
                                           'R(\d+)',
                                           'ARG90\1'),
                                        'I(\d+)',
                                        'ARG\1'));
               l_xml_tab2 := get_nodes(l_xml_tab(i), '/case/then');
               if l_xml_tab2 is null or l_xml_tab2.count = 0 then
                  cwms_err.raise(
                     'ERROR',
                     'Required <then> element not found in case '
                     ||i
                     ||' on transitional rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               elsif l_xml_tab2.count > 1 then
                  cwms_err.raise(
                     'ERROR',
                     'Multiple <then> elements found in case '
                     ||i
                     ||' on transitional rating '
                     ||self.office_id
                     ||'/'
                     ||self.rating_spec_id);
               end if;
               self.evaluations(i) := cwms_util.tokenize_expression(
                                         regexp_replace(
                                            regexp_replace(
                                               upper(get_text(l_xml_tab2(1), '/then')),
                                               'R(\d+)',
                                               'ARG90\1'),
                                            'I(\d+)',
                                            'ARG\1'));
            end loop;
         end if;
         l_xml_tab := get_nodes(l_select_xml, '/select/default');
         if l_xml_tab is null or l_xml_tab.count = 0 then
            cwms_err.raise(
               'ERROR',
               'Required <default> element not found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         elsif l_xml_tab.count > 1 then
            cwms_err.raise(
               'ERROR',
               'Multiple <default> elements found on transitional rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         self.evaluations(self.evaluations.count) := cwms_util.tokenize_expression(
                                                        regexp_replace(
                                                           regexp_replace(
                                                              upper(get_text(l_xml_tab(1), '/default')),
                                                              'R(\d+)',
                                                              'ARG90\1'),
                                                           'I(\d+)',
                                                           'ARG\1'));
      else
         -------------------
         -- simple rating --
         -------------------
         if self.rating_info is null and self.formula is null then
            cwms_err.raise(
               'ERROR',
               'One of <rating-points> or <formula> must be specified on rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         elsif self.rating_info is not null and self.formula is not null then
            cwms_err.raise(
               'ERROR',
               'Cannot specify both <rating-points> and <formula> on rating '
               ||self.office_id
               ||'/'
               ||self.rating_spec_id);
         end if;
         self.current_units := 'N';
         self.current_time  := 'D';
      end if;
      self.validate_obj;
      if not l_is_virtual and not l_is_transitional and self.rating_info is not null then
         --------------------------------------------------
         -- convert to native datum if                   --
         --   a. is a table rating, and                  --
         --   b. has elevations, and                     --
         --   c. xml specifies a non-null vertical datum --
         --------------------------------------------------
         l_elev_positions := cwms_rating.get_elevation_positions(cwms_util.split_text(self.rating_spec_id, 2, cwms_rating.separator1));
         if l_elev_positions is not null then
            l_datum := get_text(l_xml, '/*/vertical-datum');
            if l_datum is not null then
               declare
                  l_vdatum_rating vdatum_rating_t;
               begin
                  l_vdatum_rating := vdatum_rating_t(self, l_datum, l_elev_positions);
                  l_vdatum_rating.to_native_datum;
                  self := l_vdatum_rating;
               end;
            end if;
         end if;
      end if;
      return;
   end;

   constructor function rating_t(
      p_other in rating_t)
   return self as result
   is
   begin
      init(p_other);
      return;
   end;

   member procedure init(
      p_other in rating_t)
   is
   begin
      self.office_id       := p_other.office_id;
      self.rating_spec_id  := p_other.rating_spec_id;
      self.effective_date  := p_other.effective_date;
      self.transition_date := p_other.transition_date;
      self.create_date     := p_other.create_date;
      self.active_flag     := p_other.active_flag;
      self.formula         := p_other.formula;
      self.connections     := p_other.connections;
      self.native_units    := p_other.native_units;
      self.description     := p_other.description;
      self.rating_info     := p_other.rating_info;
      self.current_units   := p_other.current_units;
      self.current_time    := p_other.current_time;
      self.formula_tokens  := p_other.formula_tokens;
      self.source_ratings  := p_other.source_ratings;
      self.connections_map := p_other.connections_map;
      self.conditions      := p_other.conditions;
      self.evaluations     := p_other.evaluations;
   end;

   member procedure init(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
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
         self.transition_date := rec.transition_date;
         self.create_date    := rec.create_date;
         self.active_flag    := rec.active_flag;
         self.formula        := rec.formula;
         self.native_units   := rec.native_units;
         self.description    := rec.description;
         self.current_units  := 'D';
         self.current_time   := 'D';
         if self.formula is null and cwms_util.is_true(p_include_points) then
            self.rating_info  := rating_ind_parameter_t(p_rating_code);
         end if;
      end loop;
      if self.rating_spec_id is null then
         -----------------------------------------------------
         -- no such simple rating, check for virtual rating --
         -----------------------------------------------------
         ----------------------------------------------------------
         -- use loop for convenience - only 1 at most will match --
         ----------------------------------------------------------
         for rec in
            (  select *
                 from at_virtual_rating
                where virtual_rating_code = p_rating_code
            )
         loop
            for rec2 in
               (  select rs2.location_code
                    from at_virtual_rating_element vre,
                         at_rating_spec rs1,
                         at_rating_spec rs2
                   where rs1.rating_spec_code = rec.rating_spec_code
                     and vre.virtual_rating_code = rec.virtual_rating_code
                     and vre.rating_spec_code is not null
                     and rs2.rating_spec_code = vre.rating_spec_code
                     and rs2.location_code != rs1.location_code
               )
            loop
               cwms_err.raise(
                  'ERROR',
                  'Virtual rating cannot reference ratings for other locations.');
            end loop;

            select o.office_id,
                   bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'||rt.parameters_id
                   ||'.'||rt.version
                   ||'.'||rs.version,
                   rec.effective_date,
                   rec.transition_date,
                   rec.create_date,
                   rec.active_flag,
                   rec.connections,
                   rec.description
              into self.office_id,
                   self.rating_spec_id,
                   self.effective_date,
                   self.transition_date,
                   self.create_date,
                   self.active_flag,
                   self.connections,
                   self.description
              from at_rating_spec rs,
                   at_rating_template rt,
                   at_base_location bl,
                   at_physical_location pl,
                   cwms_office o
             where rs.rating_spec_code = rec.rating_spec_code
               and pl.location_code = rs.location_code
               and bl.base_location_code = pl.base_location_code
               and rt.template_code = rs.template_code
               and o.office_code = bl.db_office_code;

            select source_rating
                   ||' {'
                   ||reverse(regexp_replace(reverse(units), ',', ';', 1, 1))
                   ||'}'
              bulk collect
              into self.source_ratings
              from (select bl.base_location_id
                           ||substr('-', 1, length(pl.sub_location_id))
                           ||pl.sub_location_id
                           ||'.'||rt.parameters_id
                           ||'.'||rt.version
                           ||'.'||rs.version as source_rating,
                           cwms_util.join_text(
                              cast(multiset(select cwms_util.get_unit_id2(vru.unit_code)
                                              from at_virtual_rating_unit vru
                                             where vru.virtual_rating_element_code = vre.virtual_rating_element_code
                                             order by position) as str_tab_t), ','
                                              ) as units,
                           vre.position
                      from at_virtual_rating_element vre,
                           at_rating_spec rs,
                           at_rating_template rt,
                           at_base_location bl,
                           at_physical_location pl
                     where vre.virtual_rating_code = rec.virtual_rating_code
                       and vre.rating_spec_code is not null
                       and rs.rating_spec_code = vre.rating_spec_code
                       and pl.location_code = rs.location_code
                       and bl.base_location_code = pl.base_location_code
                       and rt.template_code = rs.template_code

                    union all

                    select rating_expression as source_rating,
                           cwms_util.join_text(
                              cast(multiset(select cwms_util.get_unit_id2(vru.unit_code)
                                              from at_virtual_rating_unit vru
                                             where vru.virtual_rating_element_code = vre.virtual_rating_element_code
                                             order by position) as str_tab_t), ','
                                              ) as units,
                           position
                      from at_virtual_rating_element vre
                     where vre.virtual_rating_code = rec.virtual_rating_code
                       and vre.rating_expression is not null
                   )
             order by position;

            if self.source_ratings is null or self.source_ratings.count = 0 then
               cwms_err.raise(
                  'ERROR',
                  'Virtual rating has no source ratings: '
                  ||self.office_id||'/'||self.rating_spec_id);
            end if;
         end loop;
      end if;
      if self.rating_spec_id is null then
         ---------------------------------------------------------------------
         -- no such simple or virtual rating, check for transitional rating --
         ---------------------------------------------------------------------
         ----------------------------------------------------------
         -- use loop for convenience - only 1 at most will match --
         ----------------------------------------------------------
         for rec in
            (  select *
                 from at_transitional_rating
                where transitional_rating_code = p_rating_code
            )
         loop
            for rec2 in
               (  select rs2.location_code
                    from at_transitional_rating_src trs,
                         at_rating_spec rs1,
                         at_rating_spec rs2
                   where rs1.rating_spec_code = rec.rating_spec_code
                     and trs.transitional_rating_code = rec.transitional_rating_code
                     and trs.rating_spec_code is not null
                     and rs2.rating_spec_code = trs.rating_spec_code
                     and rs2.location_code != rs1.location_code
               )
            loop
               cwms_err.raise(
                  'ERROR',
                  'Transitional rating cannot reference ratings for other locations.');
            end loop;

            select o.office_id,
                   bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'||rt.parameters_id
                   ||'.'||rt.version
                   ||'.'||rs.version,
                   rec.effective_date,
                   rec.transition_date,
                   rec.create_date,
                   rec.active_flag,
                   rec.native_units,
                   rec.description
              into self.office_id,
                   self.rating_spec_id,
                   self.effective_date,
                   self.transition_date,
                   self.create_date,
                   self.active_flag,
                   self.native_units,
                   self.description
              from at_rating_spec rs,
                   at_rating_template rt,
                   at_base_location bl,
                   at_physical_location pl,
                   cwms_office o
             where rs.rating_spec_code = rec.rating_spec_code
               and pl.location_code = rs.location_code
               and bl.base_location_code = pl.base_location_code
               and rt.template_code = rs.template_code
               and o.office_code = bl.db_office_code;

            select bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'||rt.parameters_id
                   ||'.'||rt.version
                   ||'.'||rs.version
              bulk collect
              into self.source_ratings
              from at_transitional_rating_src trs,
                   at_rating_spec rs,
                   at_rating_template rt,
                   at_base_location bl,
                   at_physical_location pl,
                   cwms_office o
             where trs.transitional_rating_code = rec.transitional_rating_code
               and rs.rating_spec_code = trs.rating_spec_code
               and pl.location_code = rs.location_code
               and bl.base_location_code = pl.base_location_code
               and rt.template_code = rs.template_code
               and o.office_code = bl.db_office_code
             order by position;

            select logic_expr_t(regexp_replace(regexp_replace(condition, 'I(\d+)', 'ARG\1'), 'R(\d+)', 'ARG90\1'))
              bulk collect
              into self.conditions
              from at_transitional_rating_sel
             where transitional_rating_code = rec.transitional_rating_code
               and position > 0
             order by position;

            select cwms_util.tokenize_expression(regexp_replace(regexp_replace(expression, 'I(\d+)', 'ARG\1'), 'R(\d+)', 'ARG90\1'))
              bulk collect
              into self.evaluations
              from at_transitional_rating_sel
             where transitional_rating_code = rec.transitional_rating_code
               and position > 0
             order by position;

            if self.evaluations is null then
               self.evaluations := str_tab_tab_t();
            end if;
            self.evaluations.extend;
            select cwms_util.tokenize_expression(regexp_replace(regexp_replace(expression, 'I(\d+)', 'ARG\1'), 'R(\d+)', 'ARG90\1'))
              into self.evaluations(self.evaluations.count)
              from at_transitional_rating_sel
             where transitional_rating_code = rec.transitional_rating_code
               and position = 0;

         end loop;
      end if;
      if self.rating_spec_id is null then
         cwms_err.raise('ERROR', 'Rating not found for code '||p_rating_code);
      end if;
      validate_obj(p_include_points);
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

   member procedure validate_obj(
      p_include_points in varchar2 default 'T')
   is
      type text_hash_t is table of boolean index by varchar(32767);
      l_code        number(10);
      l_count       pls_integer;
      l_idx         pls_integer;
      l_parts       str_tab_t;
      l_params      str_tab_t;
      l_units       str_tab_t;
      l_tokens      str_tab_t;
      l_connections str_tab_t;
      l_factor      binary_double;
      l_offset      binary_double;
      l_unconnected text_hash_t;
      l_input       varchar2(2);
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
      ------------------------
      -- ...transition date --
      ------------------------
      if self.transition_date is not null then
         if self.effective_date is null then
            cwms_err.raise('ERROR', 'Cannot have a transition date without an effective date');
         end if;
         if not self.transition_date < self.effective_date then
            cwms_err.raise('ERROR', 'Transition date is not earlier than effective date');
         end if;
      end if;
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
         l_units(l_units.count) := cwms_util.get_unit_id(l_parts(2), self.office_id);
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
         ---------------------------------------------------------------------------
         -- make sure the native units string specifies actual units, not aliases --
         ---------------------------------------------------------------------------
         self.native_units := cwms_util.get_unit_id(l_units(1), self.office_id);
         for i in 2..l_units.count-1 loop
            self.native_units := self.native_units
               ||cwms_rating.separator3
               ||cwms_util.get_unit_id(l_units(i), self.office_id);
         end loop;
         self.native_units := self.native_units
            ||cwms_rating.separator2
            ||cwms_util.get_unit_id(l_units(l_units.count), self.office_id);
      end if;
      --------------------------------------------------
      -- formula / points / connections / evaluations --
      --------------------------------------------------
      l_count := 0;
      if self.formula     is not null then l_count := l_count + 1; end if;
      if self.rating_info is not null then l_count := l_count + 1; end if;
      if self.connections is not null then l_count := l_count + 1; end if;
      if self.evaluations is not null then l_count := l_count + 1; end if;
      if l_count != 1 then
         if l_count = 0 and not cwms_util.is_true(p_include_points) then
            null;
         else
            cwms_err.raise(
               'ERROR',
               'Rating requires exactly 1 of formula, points, connections, or evalutaions, '||l_count||' specified');
         end if;
      end if;
      if self.connections is not null and self.source_ratings is null then
         cwms_err.raise(
            'ERROR',
            'Source ratings not specified with connections');
      end if;
      case
      when self.rating_info is not null or not cwms_util.is_true(p_include_points) then
         ------------------------------------------
         -- ind_params validated on construction --
         ------------------------------------------
         null;
      when self.formula is not null then
         -------------
         -- formula --
         -------------
         l_tokens := cwms_util.tokenize_expression(self.formula);
         select distinct *
           bulk collect
           into l_parts
           from (select substr(column_value, instr(column_value, '-') + 1)
           from table(l_tokens)
          where regexp_like(column_value, '-?ARG\d')
                )
          order by 1;

         for i in 1..l_parts.count loop
            if length(l_parts(i)) > 5 or instr(l_parts(i), 'ARG') != 1 then
               cwms_err.raise(
                  'ERROR',
                  'Rating formula could not be properly parsed: '||self.formula);
            end if;
         end loop;

         if to_number(substr(l_parts(l_parts.count), 4, 1)) > l_parts.count then
            cwms_err.raise(
               'ERROR',
               'Rating formula contains '
               ||cwms_util.join_text(l_parts, ',')
               ||' - expected ARG1 - ARG'
               ||l_parts.count);
         end if;
         self.formula_tokens := l_tokens;
      when self.connections is not null then
         --------------------
         -- virtual rating --
         --------------------
         declare
            type bool_tab_t is table of boolean;
            l_is_rating             bool_tab_t := bool_tab_t();
            l_rating                pls_integer;
            l_ind_param             pls_integer;
            l_ind_input             boolean;
            l_input_connections     str_tab_tab_t := str_tab_tab_t();
            l_actual_termination    varchar2(4);
            l_expected_termination  varchar2(4);
            l_rating_part           varchar2(500);
            l_units_parts           str_tab_t := str_tab_t();
            l_from_unit             varchar2(16);
            l_to_unit               varchar2(16);

            function walk_connections(
               p_input_connection     varchar2,  -- input to rating or expression (may be dep or any ind)
               p_prev_connections     str_tab_t)
               return varchar2
            is
               ll_output_connection varchar2(4); -- output from rating or expression (may be ind 1 (not expressions) or dep)
               ll_prev_rating       pls_integer;
               ll_prev_ind_param    pls_integer;
               ll_rating            pls_integer;
               ll_ind_param         pls_integer;
               ll_termination       varchar2(4);
               ll_termination2      varchar2(4);
               ll_next_conn_str     varchar2(50);
               ll_prev_connections  str_tab_t;
               ll_next_connections  str_tab_t;
            begin
               parse_connection_part(ll_prev_rating, ll_prev_ind_param, p_prev_connections(p_prev_connections.count));
               parse_connection_part(ll_rating, ll_ind_param, p_input_connection);
               --------------------------------
               -- update the connection path --
               --------------------------------
               ll_prev_connections :=  p_prev_connections;
               ll_prev_connections.extend;
               ll_prev_connections(ll_prev_connections.count) := p_input_connection;
               -----------------------------------
               -- validate the input connection --
               -----------------------------------
               case
               when ll_rating = 0 then
                  cwms_err.raise(
                     'ERROR',
                     'Virtual rating independent parameter found in connection path: '
                     ||cwms_util.join_text(ll_prev_connections, '->'));
               when ll_ind_param = 0 and not l_is_rating(ll_rating) then
                  cwms_err.raise(
                     'ERROR',
                     'Cannot reverse through rating expression at source rating '
                     ||ll_rating
                     ||' ('
                     ||self.source_ratings(ll_rating)
                     ||') in connection path '
                     ||cwms_util.join_text(ll_prev_connections, '->'));
               when ll_rating = ll_prev_rating then
                  cwms_err.raise(
                     'ERROR',
                     'Output of source rating '
                     ||ll_prev_rating
                     ||' cannot connect to same rating ('
                     ||ll_rating
                     ||') in connection path '
                     ||cwms_util.join_text(ll_prev_connections, '->'));
               else
                  null;
               end case;
               ----------------------------------------------------------------------------
               -- walk across the rating at hand, noting what is connected to its output --
               ----------------------------------------------------------------------------
               if ll_ind_param = 0 then
                   ------------------------------------------------------
                   -- can only reverse across single ind param ratings --
                   ------------------------------------------------------
                  ll_output_connection := 'R'||ll_rating||'I1';
                  ll_next_conn_str := self.connections_map(ll_rating).ind_params(1);
               else
                  ---------------------------------------------
                  -- all ind params lead to single dep param --
                  ---------------------------------------------
                  ll_output_connection := 'R'||ll_rating||'D';
                  ll_next_conn_str := self.connections_map(ll_rating).dep_param;
               end if;
               -------------------------------------------
               -- see if we're done or need to continue --
               -------------------------------------------
               if ll_next_conn_str is null then
                  --------------------------------
                  -- end of the connection path --
                  --------------------------------
                  ll_termination := ll_output_connection;
               else
                  -------------------------------------------------------------------
                  -- walk each input connected to the output of the rating at hand --
                  -------------------------------------------------------------------
                  ll_prev_connections.extend;
                  ll_prev_connections(ll_prev_connections.count) := '('||ll_output_connection||')';
                  ll_next_connections := cwms_util.split_text(ll_next_conn_str, ',');
                  for i in 1..ll_next_connections.count loop
                     if i = 1 then
                        ll_termination := walk_connections(ll_next_connections(i), ll_prev_connections);
                     else
                        ll_termination2 := walk_connections(ll_next_connections(i), ll_prev_connections);
                        if ll_termination2 != ll_termination then
                           cwms_err.raise(
                              'ERROR',
                              'Connection path '
                              ||cwms_util.join_text(ll_prev_connections, '->')
                              ||'->'
                              ||ll_next_connections(i)
                              ||' leads to different termination ('
                              ||ll_termination2
                              ||') than does connection path '
                              ||cwms_util.join_text(ll_prev_connections, '->')
                              ||'->'
                              ||ll_next_connections(1)
                              ||' ('
                              ||ll_termination
                              ||')');
                        end if;
                     end if;
                  end loop;
               end if;
               return ll_termination;
            end walk_connections;
         begin
            ---------------------------------------------------------
            -- verify the connections string is the correct format --
            ---------------------------------------------------------
            if regexp_instr(self.connections, 'R\d(D|I\d)=(R\d(D|I\d)|I\d)(,R\d(D|I\d)=(R\d(D|I\d)|I\d))*') != 1 then
               cwms_err.raise(
                  'INVALID_ITEM',
                  self.connections,
                  'virtual rating connections string');
            end if;
            l_connections := cwms_util.split_text(self.connections, ',');
            -----------------------------------------
            -- verify the source ratings are valid --
            -----------------------------------------
            l_is_rating.extend(self.source_ratings.count);
            l_units_parts.extend(self.source_ratings.count);
            for i in 1..self.source_ratings.count loop
               parse_source_rating(l_is_rating(i), l_rating_part, l_units_parts(i), self.source_ratings(i));
               if l_is_rating(i) then
                  -----------------------
                  -- valid rating spec --
                  -----------------------
                  null;
               else
                  ----------------------------------------------------------------------
                  -- valid rating expression, make sure we have consecutive arguments --
                  ----------------------------------------------------------------------
                  l_tokens := cwms_util.tokenize_expression(regexp_replace(l_rating_part, 'I(\d+)', 'ARG\1'));
                  select distinct
                         substr(column_value, instr(column_value, '-') + 1)
                    bulk collect
                    into l_parts
                    from table(l_tokens)
                   where regexp_like(column_value, '-?ARG\d')
                   order by 1;
                  if to_number(substr(l_parts(l_parts.count), 4, 1)) != l_parts.count then
                     cwms_err.raise(
                        'ERROR',
                        'Source rating '
                        ||i
                        ||' (expression = '
                        ||self.source_ratings(i)
                        ||') contains '
                        ||cwms_util.join_text(l_parts, ',')
                        ||' - expected I1 - I'
                        ||l_parts.count);
                  end if;
                  --------------------------------------------
                  -- save the RPN version of the expression --
                  --------------------------------------------
                  self.source_ratings(i) := cwms_util.join_text(l_tokens, ' ')||' {'||l_units_parts(i)||'}';
               end if;
            end loop;
            -----------------------------------
            -- intialize the connections map --
            -----------------------------------
            self.connections_map := rating_conn_map_tab_t();
            self.connections_map.extend(self.source_ratings.count);
            for i in 1..self.source_ratings.count loop
               self.connections_map(i) := rating_conn_map_t(
                  str_tab_t(),     -- ind_params
                  null,            -- dep_param
                  str_tab_t(),     -- units
                  double_tab_t(),  -- factors
                  double_tab_t()); -- offsets
               if l_is_rating(i) then
                  l_count := cwms_rating.get_ind_parameter_count(self.source_ratings(i));
               else
                  l_count := rating_expr_ind_param_count(self.source_ratings(i));
               end if;
               self.connections_map(i).ind_params.extend(l_count);
               self.connections_map(i).factors.extend(l_count+1);
               self.connections_map(i).offsets.extend(l_count+1);
               self.connections_map(i).units := cwms_util.split_text(
                  replace(l_units_parts(i), cwms_rating.separator2, cwms_rating.separator3),
                  cwms_rating.separator3);
               if self.connections_map(i).units.count != l_count + 1 then
                  cwms_err.raise(
                     'ERROR',
                     'Source rating '
                     ||i
                     ||' specifies '
                     ||self.connections_map(i).units.count
                     ||' units when '
                     ||(l_count+1)
                     ||' are required ('
                     ||l_count
                     ||' independent parameters plus one dependent parameter)');
               end if;
            end loop;
            ------------------------------
            -- populate the connections --
            ------------------------------
            for i in 1..self.get_ind_parameter_count loop
               l_unconnected('I'||i) := true;
            end loop;
            for i in 1..l_connections.count loop
               l_parts := cwms_util.split_text(l_connections(i), '=');
               for j in 1..2 loop
                  ---------------------------------------------------------------------------------------------
                  -- store l_parts(2) in slot specified by l_parts(1)                                        --
                  -- store l_parts(1) in slot specified by l_parts(2) unless l_parts(2) specifies input data --
                  ---------------------------------------------------------------------------------------------
                  if j = 2 and substr(l_parts(j), 1, 1) = 'I' then
                     l_unconnected.delete(l_parts(j));
                     l_idx := to_number(substr(l_parts(j), 2, 1));
                     if not l_idx between 1 and l_count then
                        cwms_err.raise(
                           'ERROR',
                           'Connection part "'
                           ||l_parts(j)
                           ||'" of "'
                           ||l_connections(i)
                           ||'" specifies invalid independent parameter number, must be in range 1..'
                           ||l_count);
                     end if;
                     exit;
                  end if;
                  parse_connection_part(l_rating, l_ind_param,l_parts(j));
                  if not l_rating between 1 and self.connections_map.count then
                     cwms_err.raise(
                        'ERROR',
                        'Connection part "'
                        ||l_parts(j)
                        ||'" of "'
                        ||l_connections(i)
                        ||'" specifies invalid rating number, must be in range 1..'
                        ||self.connections_map.count);
                  end if;
                  if l_ind_param > 0 then
                     -----------------------------------------------------------
                     -- l_parts(j) specifies independent parameter connection --
                     -----------------------------------------------------------
                     if l_ind_param > self.connections_map(l_rating).ind_params.count then
                        cwms_err.raise(
                           'ERROR',
                           'Connection part "'
                           ||l_parts(j)
                           ||'" of "'
                           ||l_connections(i)
                           ||'" specifies invalid independent parameter number, must be in range 1..'
                           ||self.connections_map(l_rating).ind_params.count);
                     end if;
                     case
                     when self.connections_map(l_rating).ind_params(l_ind_param) is null then
                        --------------------------------
                        -- first connection specified --
                        --------------------------------
                        self.connections_map(l_rating).ind_params(l_ind_param) := l_parts(mod(j,2)+1);
                     when instr(self.connections_map(l_rating).ind_params(l_ind_param), l_parts(mod(j,2)+1)) = 0 then
                        -------------------------------------
                        -- additional connection specified --
                        -------------------------------------
                        self.connections_map(l_rating).ind_params(l_ind_param) :=
                        self.connections_map(l_rating).ind_params(l_ind_param) || ',' || l_parts(mod(j,2)+1);
                     else
                        ------------------------------------
                        -- duplicate connection specified --
                        ------------------------------------
                        null;
                     end case;
                  else
                     ---------------------------------------------------------
                     -- l_parts(j) specifies dependent parameter connection --
                     ---------------------------------------------------------
                     case
                     when self.connections_map(l_rating).dep_param is null then
                        --------------------------------
                        -- first connection specified --
                        --------------------------------
                        self.connections_map(l_rating).dep_param := l_parts(mod(j,2)+1);
                     when instr(self.connections_map(l_rating).dep_param, l_parts(mod(j,2)+1)) = 0 then
                        -------------------------------------
                        -- additional connection specified --
                        -------------------------------------
                        self.connections_map(l_rating).dep_param :=
                        self.connections_map(l_rating).dep_param || ',' || l_parts(mod(j,2)+1);
                     else
                        ------------------------------------
                        -- duplicate connection specified --
                        ------------------------------------
                        null;
                     end case;
                  end if;
               end loop;
            end loop;
            ---------------------------------------------------------------------------------------
            -- serially assign unconnected source rating ind_params and dep_params to input data --
            ---------------------------------------------------------------------------------------
            l_input := l_unconnected.first;
            if l_input is not null then
               <<connections_map>>
               for i in 1..self.connections_map.count loop
                  for j in 1..self.connections_map(i).ind_params.count loop
                        exit connections_map when l_input is null;
                     if self.connections_map(i).ind_params(j) is null then
                           self.connections_map(i).ind_params(j) := l_input;
                           l_input := l_unconnected.next(l_input);
                     end if;
                  end loop;
                     exit when l_input is null;
                  if self.connections_map(i).dep_param is null then
                     l_count := l_count + 1;
                        self.connections_map(i).dep_param := l_input;
                        l_input := l_unconnected.next(l_input);
                  end if;
                     exit when l_input is null;
               end loop;
            end if;
            -----------------------------------------
            -- validate the data input connections --
            -----------------------------------------
            l_input_connections.extend(self.get_ind_parameter_count);
            for i in 1..l_input_connections.count loop
               l_input_connections(i) := str_tab_t();
            end loop;
            for i in 1..self.connections_map.count loop
               l_ind_input := false;
               for j in 1..self.connections_map(i).ind_params.count loop
                  l_parts := cwms_util.split_text(self.connections_map(i).ind_params(j), ',');
                  for k in 1..l_parts.count loop
                     if substr(l_parts(k), 1, 1) = 'I' then
                        l_ind_input := true;
                        l_count := to_number(substr(l_parts(k), 2, 1));
                        l_input_connections(l_count).extend;
                        l_input_connections(l_count)(l_input_connections(l_count).count) := 'R'||i||'I'||j;
                     end if;
                  end loop;
               end loop;
               l_parts := cwms_util.split_text(self.connections_map(i).dep_param, ',');
               for k in 1..l_parts.count loop
                  if substr(l_parts(k), 1, 1) = 'I' then
                     if l_ind_input then
                        cwms_err.raise(
                           'ERROR',
                           'Source rating '
                           ||i
                           ||' has independent parameters of the virtual rating mapped to its independent and dependent paramters');
                     end if;
                     l_count := to_number(substr(l_parts(k), 2, 1));
                     l_input_connections(l_count).extend;
                     l_input_connections(l_count)(l_input_connections(l_count).count) := 'R'||i||'D';
                  end if;
               end loop;
            end loop;
            for i in 1..l_input_connections.count loop
               if l_input_connections(i).count = 0 then
                  cwms_err.raise(
                     'ERROR',
                     'Virtual rating independent parameter '
                     ||i
                     ||' is not mapped to any source rating parameter');
               end if;
               for j in 1..l_input_connections(i).count loop
                  parse_connection_part(l_rating, l_ind_param,l_input_connections(i)(j));
                  if l_ind_param = 0 then
                     select count(*)
                       into l_count
                       from table(cwms_util.split_text(self.connections_map(l_rating).dep_param, ','));
                     if l_count > 1 then
                        cwms_err.raise(
                           'ERROR',
                           'Virtual rating independent parameter '
                           ||i
                           ||' cannot be mapped with other connections at R'
                           ||l_rating
                           ||'D');
                     end if;
                  else
                     select count(*)
                       into l_count
                       from table(cwms_util.split_text(self.connections_map(l_rating).ind_params(l_ind_param), ','));
                     if l_count > 1 then
                        cwms_err.raise(
                           'ERROR',
                           'Virtual rating independent parameter '
                           ||i
                           ||' cannot be mapped with other connections at R'
                           ||l_rating
                           ||'I'
                           ||l_ind_param);
                     end if;
                  end if;
               end loop;
            end loop;
            -------------------------------------------------------------
            -- verify that each data input leads to the correct output --
            -------------------------------------------------------------
            if self.connections_map(self.connections_map.count).dep_param is null then
               l_expected_termination := 'R'||self.connections_map.count||'D';
            else
               l_expected_termination := 'R'||self.connections_map.count||'I1';
            end if;
            for i in 1..l_input_connections.count loop
               for j in 1..l_input_connections(i).count loop
                  l_actual_termination := walk_connections(l_input_connections(i)(j), str_tab_t('I'||l_input_connections.count));
                  if l_actual_termination != l_expected_termination then
                     cwms_err.raise(
                        'ERROR',
                        'The connection path for virtual rating indpendent parameter '
                        ||i
                        ||' connection '
                        ||j
                        ||' ('
                        ||l_input_connections(i)(j)
                        ||') terminates at '
                        ||l_actual_termination
                        ||' instead of the expected termination connection of '
                        ||l_expected_termination);
                  end if;
               end loop;
            end loop;
            -------------------------------------------------------------
            -- populate the rating native units from the element units --
            -------------------------------------------------------------
            l_units := str_tab_t();
            l_units.extend(self.get_ind_parameter_count + 1);
            for i in 1..self.connections_map.count loop
               for j in 1..self.connections_map(i).ind_params.count loop
                  if substr(self.connections_map(i).ind_params(j), 1, 1) = 'I' then
                     l_units(to_number(substr(self.connections_map(i).ind_params(j), 2))) := self.connections_map(i).units(j);
                  end if;
               end loop;
               if substr(self.connections_map(i).dep_param, 1, 1) = 'I' then
                  l_units(to_number(substr(self.connections_map(i).dep_param, 2))) := self.connections_map(i).units(self.connections_map(i).units.count);
               end if;
            end loop;
            parse_connection_part(l_rating, l_ind_param, l_expected_termination);
            if l_ind_param = 0 then
               l_units(l_units.count) := self.connections_map(l_rating).units(self.connections_map(l_rating).units.count);
            else
               l_units(l_units.count) := self.connections_map(l_rating).units(l_ind_param);
            end if;
            self.native_units := l_units(1);
            for i in 2..l_units.count loop
               if i = l_units.count then
                  self.native_units := self.native_units||';'||l_units(i);
               else
                  self.native_units := self.native_units||','||l_units(i);
               end if;
            end loop;
            ---------------------------------------------------------
            -- populate the internal connection conversion factors --
            ---------------------------------------------------------
            for i in 1..self.connections_map.count loop
               for j in 1..self.connections_map(i).ind_params.count loop
                  if self.connections_map(i).ind_params(j) is not null and substr(self.connections_map(i).ind_params(j), 1, 1) != 'I' then
                     l_from_unit := self.connections_map(i).units(j);
                     parse_connection_part(l_rating, l_ind_param, self.connections_map(i).ind_params(j));
                     begin
                        if l_rating > 0 then
                           if l_ind_param = 0 then
                              l_to_unit := self.connections_map(l_rating).units(self.connections_map(l_rating).units.count);
                           else
                              l_to_unit := self.connections_map(l_rating).units(l_ind_param);
                           end if;
                        end if;
                        select factor,
                               offset
                          into self.connections_map(i).factors(j),
                               self.connections_map(i).offsets(j)
                          from cwms_unit_conversion
                         where from_unit_id = cwms_util.get_unit_id(l_from_unit, self.office_id)
                           and to_unit_id = cwms_util.get_unit_id(l_to_unit, self.office_id);

                        if self.connections_map(i).factors(j) is null
                        or self.connections_map(i).offsets(j) is null then
                           cwms_err.raise('ERROR', 'Null conversion factor');
                        end if;
                     exception
                        when others then
                           cwms_err.raise(
                              'ERROR',
                              'Cannot convert from rating '
                              ||i
                              ||' independent parameter '
                              ||j
                              ||' unit of '
                              ||l_from_unit
                              ||' to rating '
                              ||l_rating
                              ||case l_ind_param
                                   when 0 then ' dependent parameter unit of '
                                   else ' independent parameter '||l_ind_param||' unit of '
                                end
                              ||l_to_unit
                              ||' on connection R'
                              ||i
                              ||'I'
                              ||j
                              ||'='
                              ||self.connections_map(i).ind_params(j));
                     end;
                  end if;
               end loop;
               if self.connections_map(i).dep_param is not null and substr(self.connections_map(i).dep_param, 1, 1) != 'I' then
                  l_from_unit := self.connections_map(i).units(self.connections_map(i).units.count);
                  parse_connection_part(l_rating, l_ind_param, self.connections_map(i).dep_param);
                  begin
                     if l_rating > 0 then
                        if l_ind_param = 0 then
                           l_to_unit := self.connections_map(l_rating).units(self.connections_map(l_rating).units.count);
                        else
                           l_to_unit := self.connections_map(l_rating).units(l_ind_param);
                        end if;
                     end if;
                     select factor,
                            offset
                       into self.connections_map(i).factors(self.connections_map(i).factors.count),
                            self.connections_map(i).offsets(self.connections_map(i).offsets.count)
                       from cwms_unit_conversion
                      where from_unit_id = cwms_util.get_unit_id(l_from_unit, self.office_id)
                        and to_unit_id = cwms_util.get_unit_id(l_to_unit, self.office_id);

                     if self.connections_map(i).factors(self.connections_map(i).factors.count) is null
                     or self.connections_map(i).offsets(self.connections_map(i).offsets.count) is null then
                        cwms_err.raise('ERROR', 'Null conversion factor');
                     end if;
                  exception
                     when others then
                        cwms_err.raise(
                           'ERROR',
                           'Cannot convert from rating '
                           ||i
                           ||' dependent parameter unit of '
                           ||l_from_unit
                           ||' to rating '
                           ||l_rating
                           ||case l_ind_param
                                when 0 then ' dependent parameter unit of '
                                else ' independent parameter '||l_ind_param||' unit of '
                             end
                           ||l_to_unit
                           ||' on connection R'
                           ||i
                           ||'D='
                           ||self.connections_map(i).dep_param);
                  end;
               end if;
            end loop;
         end;
      when self.evaluations is not null then
         -------------------------
         -- transitional rating --
         -------------------------
         if (self.evaluations.count = 1 and (self.conditions is not null and self.conditions.count != 0)) or
            (self.evaluations.count > 1 and (self.conditions is null or self.conditions.count != self.evaluations.count - 1))
         then
            cwms_err.raise(
               'ERROR',
               'The number of evaluations must be one greater than the number of conditions on a transitional rating');
         end if;
         for i in 1..self.evaluations.count loop
            for j in 1..self.evaluations(i).count loop
               l_count := instr(evaluations(i)(j), 'ARG90');
               if l_count > 0 and to_number(substr(evaluations(i)(j), l_count+5)) > self.source_ratings.count then
                  cwms_err.raise(
                     'ERROR',
                     'Transitional rating evaluation '
                     ||i
                     ||' references source rating '
                     ||to_number(substr(evaluations(i)(j), l_count+5))
                     ||', but only '
                     ||self.source_ratings.count
                     ||' source ratings are specified');
               end if;
            end loop;
         end loop;
      end case;
   end;

   member function rating_expr_ind_param_count(
      p_text in varchar2)
      return pls_integer
   is
      l_parts str_tab_t;
   begin
      select distinct
             substr(column_value, instr(column_value, '-') + 1)
        bulk collect
        into l_parts
        from table(cwms_util.split_text(p_text))
       where regexp_like(column_value, '-?ARG\d')
       order by 1;

      return l_parts.count;
   end rating_expr_ind_param_count;

   member procedure parse_source_rating(
      self           in  rating_t, -- to keep from implicity being defined as OUT type
      p_is_rating    out boolean,
      p_rating_part  out varchar2,
      p_units_part   out varchar2,
      p_text         in  varchar2)
   is
      l_parts       str_tab_t;
      l_tokens      str_tab_t;
      l_pos         pls_integer;
      l_rating_spec rating_spec_t;
   begin
      l_parts := str_tab_t();
      l_parts.extend(2);
      l_pos := instr(p_text, '{', -1);
      if l_pos = 0 then
         l_parts(1) := trim(p_text);
      else
         l_parts(1) := trim(substr(p_text, 1, l_pos-1));
         l_parts(2) := trim(substr(p_text, l_pos+1));
         if substr(l_parts(2), length(l_parts(2))) = '}' then
            l_parts(2) := trim(substr(l_parts(2), 1, length(l_parts(2))-1));
         end if;
      end if;
      begin
         l_rating_spec := rating_spec_t(l_parts(1), self.office_id);
         p_is_rating := true;
      exception
         when others then
            begin
               l_tokens := cwms_util.tokenize_expression(l_parts(1));
               for i in 1..l_tokens.count loop
                  case
                  when cwms_util.is_expression_constant(l_tokens(i))  then null;
                  when cwms_util.is_expression_function(l_tokens(i))  then null;
                  when cwms_util.is_expression_operator(l_tokens(i))  then null;
                  when regexp_instr(l_tokens(i), '^-?(I|ARG)\d$') = 1 then null;
                  else
                     declare
                        x number;
                     begin
                        x := to_number(l_tokens(i));
                     exception 
                        when others then cwms_err.raise('INVALID_ITEM', l_tokens(i), 'math expression token');
                     end;
                  end case;
               end loop;
               p_is_rating := false;
            exception
               when others then
                  cwms_err.raise(
                     'INVALID_ITEM',
                     l_parts(1),
                     'CWMS rating spec or math expression');
            end;
      end;
      p_rating_part := l_parts(1);
      p_units_part  := l_parts(2);
   end parse_source_rating;

   member procedure parse_connection_part(
      self        in  rating_t, -- to keep from implicity being defined as OUT type
      p_rating    out pls_integer,
      p_ind_param out pls_integer,
      p_conn_part in  varchar2)
   is
      l_valid boolean := false;
      l_conn_part varchar2(8);
   begin
      if substr(p_conn_part, 1, 1) = '(' then
         l_conn_part := substr(p_conn_part, 2, length(p_conn_part)-2);
      else
         l_conn_part := p_conn_part;
      end if;
      begin
         case length(l_conn_part)
         when 2 then
            if substr(l_conn_part, 1, 1) = 'I' then
               p_rating := 0;
               p_ind_param := to_number(substr(l_conn_part, 2, 1));
               l_valid := true;
            end if;
         when 3 then
            if substr(l_conn_part, 1, 1) = 'R' then
               p_rating := to_number(substr(l_conn_part, 2, 1));
               if substr(l_conn_part, 3, 1) = 'D' then
                  p_ind_param := 0;
                  l_valid := true;
               end if;
            end if;
         when 4 then
            if substr(l_conn_part, 1, 1) = 'R' then
               p_rating := to_number(substr(l_conn_part, 2, 1));
               if substr(l_conn_part, 3, 1) = 'I' then
                  p_ind_param := to_number(substr(l_conn_part, 4, 1));
                  l_valid := true;
               end if;
            end if;
         else
            null;
         end case;
      exception
         when others then null;
      end;
      if not l_valid then
         cwms_err.raise('INVALID_ITEM', l_conn_part, 'virtual rating connection part');
      end if;
   end parse_connection_part;

   member procedure convert_to_database_units
   is
      l_parts str_tab_t;
   begin
      if self.rating_info is null then
         self.current_units := 'D';
      else
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
      end if;
   end;

   member procedure convert_to_native_units
   is
      l_parts str_tab_t;
   begin
      if self.rating_info is null then
         self.current_units := 'N';
      else
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
      end if;
   end;

   member procedure convert_to_database_time
   is
      l_local_timezone varchar2(28);
      l_location_id    varchar2(57);
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
         if self.effective_date is not null then
               self.effective_date := cwms_util.change_timezone(self.effective_date, l_local_timezone, 'UTC');
         end if;
               if self.transition_date is not null then
                     self.transition_date := cwms_util.change_timezone(self.transition_date, l_local_timezone, 'UTC');
               end if;
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
      l_location_id    varchar2(57);
   begin
         case self.current_time
            when 'D' then
               l_location_id := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1)(1);
               l_local_timezone := cwms_loc.get_local_timezone(l_location_id, self.office_id);
               if l_local_timezone is null then
                  cwms_err.raise('ERROR', 'Location '||l_location_id||' does not have a time zone set');
               end if;
         if self.effective_date is not null then
               self.effective_date := cwms_util.change_timezone(self.effective_date, 'UTC', l_local_timezone);
         end if;
               if self.transition_date is not null then
                     self.transition_date := cwms_util.change_timezone(self.transition_date, 'UTC', l_local_timezone);
               end if;
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
      l_rating_rec  at_rating%rowtype;
      l_vrating_rec at_virtual_rating%rowtype;
      l_trating_rec at_transitional_rating%rowtype;
      l_exists      boolean := true;
      l_clone       rating_t;
      l_msg         sys.aq$_jms_map_message;
      l_msgid       pls_integer;
      i             integer;
      l_is_rating   boolean;
      l_rating_part varchar2(500);
      l_units_part  varchar2(50);
      l_units       str_tab_t;
      l_units_rec   at_virtual_rating_unit%rowtype;
   begin
      case
      when self.source_ratings is null then
         ---------------------
         -- concrete rating --
         ---------------------
         if self.current_units = 'N' or self.current_time = 'L' then
            l_clone := rating_t(self);
            if self.current_units = 'N' then
               l_clone.convert_to_database_units;
            end if;
            if self.current_time = 'L' then
               l_clone.convert_to_database_time;
            end if;
            l_clone.store(p_rating_code, p_fail_if_exists);
            return;
         end if;
         l_rating_rec.rating_spec_code := rating_spec_t.get_rating_spec_code(
            self.rating_spec_id,
            self.office_id);
         l_rating_rec.effective_date := self.effective_date;

         begin
            select *
              into l_rating_rec
              from at_rating
             where rating_spec_code = l_rating_rec.rating_spec_code
               and effective_date = l_rating_rec.effective_date;

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
               l_rating_rec.rating_code := cwms_seq.nextval;
         end;

         l_rating_rec.ref_rating_code := null;
         l_rating_rec.transition_date := self.transition_date;
         l_rating_rec.create_date     := nvl(self.create_date, cast(systimestamp at time zone 'UTC' as date));
         l_rating_rec.active_flag     := self.active_flag;
         l_rating_rec.formula         := self.formula;
         l_rating_rec.native_units    := self.native_units;
         l_rating_rec.description     := self.description;

         if l_exists then
            update at_rating
               set row = l_rating_rec
             where rating_code = l_rating_rec.rating_code;
         else
            insert
              into at_rating
            values l_rating_rec;
         end if;

         if self.rating_info is not null then
            self.rating_info.store(l_rating_rec.rating_code, null, 'F');
         end if;

         p_rating_code := l_rating_rec.rating_code;
      when self.connections is not null then
         --------------------
         -- virtual rating --
         --------------------
         l_vrating_rec.rating_spec_code := rating_spec_t.get_rating_spec_code(
            self.rating_spec_id,
            self.office_id);

         begin
            select *
              into l_vrating_rec
              from at_virtual_rating
             where rating_spec_code = l_vrating_rec.rating_spec_code;

            if cwms_util.is_true(p_fail_if_exists) then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Virtual rating',
                  self.office_id
                  ||'/'
                  ||self.rating_spec_id);
            end if;
         exception
            when no_data_found then l_exists := false;
         end;
         l_vrating_rec.effective_date := self.effective_date;
         l_vrating_rec.transition_date := self.transition_date;
         l_vrating_rec.create_date    := nvl(self.create_date, sysdate);
         l_vrating_rec.active_flag    := self.active_flag;
         l_vrating_rec.connections := self.connections;
         l_vrating_rec.description := self.description;
         if l_exists then
            delete
              from at_virtual_rating_unit
             where virtual_rating_element_code in
                   (select virtual_rating_element_code
                      from at_virtual_rating_element
                     where virtual_rating_code = l_vrating_rec.virtual_rating_code
                   );
            delete
              from at_virtual_rating_element
             where virtual_rating_code = l_vrating_rec.virtual_rating_code;

            update at_virtual_rating
               set row = l_vrating_rec
             where virtual_rating_code = l_vrating_rec.virtual_rating_code;

         else
            l_vrating_rec.virtual_rating_code := cwms_seq.nextval;
            insert
              into at_virtual_rating
            values l_vrating_rec;
         end if;

         for j in 1..self.source_ratings.count loop
            parse_source_rating(l_is_rating, l_rating_part, l_units_part, self.source_ratings(j));
            if l_is_rating then
               insert
                 into at_virtual_rating_element
               values (cwms_seq.nextval,
                       l_vrating_rec.virtual_rating_code,
                       j,
                       rating_spec_t.get_rating_spec_code(l_rating_part, self.office_id),
                       null
                      )
               return virtual_rating_element_code
                 into l_units_rec.virtual_rating_element_code;
            else
               insert
                 into at_virtual_rating_element
               values (cwms_seq.nextval,
                       l_vrating_rec.virtual_rating_code,
                       j,
                       null,
                       l_rating_part
                      )
               return virtual_rating_element_code
                 into l_units_rec.virtual_rating_element_code;
            end if;
            l_units := cwms_util.split_text(replace(l_units_part, cwms_rating.separator2, cwms_rating.separator3), cwms_rating.separator3);
            if l_units is null or l_units.count = 0 then
               cwms_err.raise('ERROR', 'No units on source rating '||j||' ('||self.source_ratings(j)||')');
            end if;
            for k in 1..l_units.count loop
               l_units_rec.position := k;
               begin
                  select unit_code
                    into l_units_rec.unit_code
                    from cwms_unit
                   where unit_id = cwms_util.get_unit_id(l_units(k), self.office_id);
               exception
                  when no_data_found then
                     cwms_err.raise(
                        'ERROR',
                        'Invalid unit ('
                        ||l_units(k)
                        ||') in source rating '
                        ||j
                        ||' ('
                        ||self.source_ratings(j)
                        ||')');
               end;
               insert
                 into at_virtual_rating_unit
               values l_units_rec;
            end loop;
         end loop;
      when self.evaluations is not null then
         -------------------------
         -- transitional rating --
         -------------------------
         l_trating_rec.rating_spec_code := rating_spec_t.get_rating_spec_code(
            self.rating_spec_id,
            self.office_id);

         begin
            select *
              into l_trating_rec
              from at_transitional_rating
             where rating_spec_code = l_trating_rec.rating_spec_code;

            if cwms_util.is_true(p_fail_if_exists) then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Transitional rating',
                  self.office_id
                  ||'/'
                  ||self.rating_spec_id);
      end if;
         exception
            when no_data_found then l_exists := false;
         end;

         l_trating_rec.effective_date := self.effective_date;
         l_trating_rec.transition_date := self.transition_date;
         l_trating_rec.create_date    := nvl(self.create_date, sysdate);
         l_trating_rec.active_flag    := self.active_flag;
         l_trating_rec.native_units   := self.native_units;
         l_trating_rec.description    := self.description;

         if l_exists then
            update at_transitional_rating
               set row = l_trating_rec
             where transitional_rating_code = l_trating_rec.transitional_rating_code;

            delete
              from at_transitional_rating_sel
             where transitional_rating_code = l_trating_rec.transitional_rating_code;

            delete
              from at_transitional_rating_src
             where transitional_rating_code = l_trating_rec.transitional_rating_code;
         else
            l_trating_rec.transitional_rating_code := cwms_seq.nextval;
            insert
              into at_transitional_rating
            values l_trating_rec;
         end if;


         for i in 1..self.source_ratings.count loop
            insert
              into at_transitional_rating_src
            values (l_trating_rec.transitional_rating_code,
                    i,
                    rating_spec_t.get_rating_spec_code(self.source_ratings(i), self.office_id)
                   );
         end loop;

         declare
            l_rpn varchar2(256);
            l_count pls_integer := self.evaluations.count;
         begin
            for i in 1..l_count-1 loop
               l_rpn := null;
               self.conditions(i).to_rpn(l_rpn);
               insert
                 into at_transitional_rating_sel
               values (l_trating_rec.transitional_rating_code,
                       i,
                       replace(cwms_util.join_text(self.evaluations(i), ' '), 'ARG90', 'R'),
                       replace(l_rpn, 'ARG', 'I')
                      );
            end loop;
            insert
              into at_transitional_rating_sel
            values (l_trating_rec.transitional_rating_code,
                    0,
                    replace(cwms_util.join_text(self.evaluations(l_count), ' '), 'ARG90', 'R'),
                    null
                   );
         end;

      else
         cwms_err.raise(
            'ERROR',
            'Cannot recognize rating '
            ||self.office_id
            ||'/'
            ||self.rating_spec_id
            ||' as simple, virtual, or transitional rating');
      end case;

      cwms_msg.new_message(l_msg, l_msgid, 'RatingStored');
      l_msg.set_string(l_msgid, 'office_id', self.office_id);
      l_msg.set_string(l_msgid, 'rating_id', self.rating_spec_id);
      l_msg.set_string(l_msgid, 'active',    self.active_flag);
      l_msg.set_string(l_msgid, 'is_virtual', case self.connections is null when true then 'false' else 'true' end);
      l_msg.set_string(l_msgid, 'is_transitional', case self.evaluations is null when true then 'false' else 'true' end);
      l_msg.set_long(l_msgid, 'create_date',    cwms_util.to_millis(self.create_date));
      l_msg.set_long(l_msgid, 'effective_date', cwms_util.to_millis(self.effective_date));
      l_msg.set_long(l_msgid, 'transition_date', cwms_util.to_millis(self.transition_date));
      i := cwms_msg.publish_message(l_msg, l_msgid, self.office_id||'_ts_stored');
      cwms_msg.new_message(l_msg, l_msgid, 'RatingStored');
      l_msg.set_string(l_msgid, 'office_id', self.office_id);
      l_msg.set_string(l_msgid, 'rating_id', self.rating_spec_id);
      l_msg.set_string(l_msgid, 'active',    self.active_flag);
      l_msg.set_string(l_msgid, 'is_virtual', case self.connections is null when true then 'false' else 'true' end);
      l_msg.set_string(l_msgid, 'is_transitional', case self.evaluations is null when true then 'false' else 'true' end);
      l_msg.set_long(l_msgid, 'create_date',    cwms_util.to_millis(self.create_date));
      l_msg.set_long(l_msgid, 'effective_date', cwms_util.to_millis(self.effective_date));
      l_msg.set_long(l_msgid, 'transition_date', cwms_util.to_millis(self.transition_date));
      i := cwms_msg.publish_message(l_msg, l_msgid, self.office_id||'_realtime_ops');
   end;

   member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rating_code number(10);
   begin
      self.store(l_rating_code, p_fail_if_exists);
   end;

   member function to_clob(
      self         in out nocopy rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return clob
   is
      l_text               clob;
      l_clone              rating_t;
      l_tzone              varchar2(28);
      l_units              varchar2(128);
      l_is_virtual         boolean;
      l_is_transitional    boolean;
      l_rating_spec        rating_spec_t;
      l_rating_tag         varchar2(19);
      l_source_rating_type varchar2(17);
      l_parts              str_tab_t;

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
      l_is_virtual := self.connections is not null;
      l_is_transitional := self.evaluations is not null;
      l_rating_tag := case
                      when l_is_virtual      then 'virtual-rating'
                      when l_is_transitional then 'transitional-rating'
                      else                        'simple-rating'
                      end;
      ---------------------------------------------------------------------------
      -- clone the current rating so we can change its properties if necessary --
      ---------------------------------------------------------------------------
      case
      when self is of (vdatum_rating_t) then
         l_clone := vdatum_rating_t(treat(self as vdatum_rating_t));
      else
         l_clone := rating_t(self);
      end case;
      --------------------------
      -- handle the time zone --
      --------------------------
      l_tzone := coalesce(
         p_timezone,
         cwms_loc.get_local_timezone(cwms_util.split_text(l_clone.rating_spec_id, cwms_rating.separator1)(1), l_clone.office_id),
         'UTC');
      ----------------------
      -- handle the units --
      ----------------------
      if upper(trim(nvl(p_units, 'NATIVE'))) = 'NATIVE' then
         l_clone.convert_to_native_units;
      else
         l_clone.convert_to_database_units;
         l_parts := cwms_util.split_text(replace(cwms_util.split_text(l_clone.rating_spec_id, 2, '.'), ';', ','), ',');
         for i in 1..l_parts.count loop
            l_units := l_units || case i when 1 then null when l_parts.count then ';' else ',' end;
            l_units := l_units || cwms_util.get_default_units(l_parts(i), upper(trim(p_units)));
         end loop;
         l_clone.native_units := l_units;
         l_clone.convert_to_native_units;
      end if;
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<'||l_rating_tag||' office-id="'||l_clone.office_id||'"><rating-spec-id>'||l_clone.rating_spec_id||'</rating-spec-id>');
      if not l_is_virtual then
         cwms_util.append(l_text, '<units-id>'||l_clone.native_units||'</units-id>');
      end if;
      cwms_util.append(l_text, '<effective-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_clone.effective_date, 'UTC', l_tzone), l_tzone)||'</effective-date>');
      if l_clone.transition_date is null then
         null; -- cwms_util.append(l_text, '<transition-start-date/>');
      else
         cwms_util.append(l_text, '<transition-start-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_clone.transition_date, 'UTC', l_tzone), l_tzone)||'</transition-start-date>');
      end if;
      if l_clone.create_date is null then
         cwms_util.append(l_text, '<create-date/>');
      else
            cwms_util.append(l_text, '<create-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_clone.create_date, 'UTC', l_tzone), l_tzone)||'</create-date>');
         end if;
      cwms_util.append(l_text, '<active>'||bool_text(cwms_util.is_true(l_clone.active_flag))||'</active>');
      if l_clone.description is null then
         cwms_util.append(l_text, '<description/>');
      else
         cwms_util.append(l_text, '<description>'||l_clone.description||'</description>');
      end if;
      case
      when l_is_virtual then
         ------------------
         -- virtual only --
         ------------------
         cwms_util.append(l_text, '<connections>'||l_clone.connections||'</connections>');
         cwms_util.append(l_text, '<source-ratings>');
         for i in 1..l_clone.source_ratings.count loop
            begin
               l_rating_spec := rating_spec_t(trim(cwms_util.split_text(l_clone.source_ratings(i), 1, '{')), l_clone.office_id);
               l_source_rating_type := 'rating-spec-id';
            exception
               when others then l_source_rating_type := 'rating-expression';
            end;
            cwms_util.append(
               l_text,
               '<source-rating position="'
               ||i
               ||'"><'
               ||l_source_rating_type
               ||'>'
               ||case l_source_rating_type
                    when 'rating-expression' then
                       regexp_replace(cwms_util.to_algebraic(cwms_util.split_text(l_clone.source_ratings(i), 1, '{')), 'ARG(\d+)', 'I\1')
                       ||' '
                       ||substr(l_clone.source_ratings(i), instr(l_clone.source_ratings(i), '{'))
                    else
                       l_clone.source_ratings(i)
                 end
               ||'</'
               ||l_source_rating_type
               ||'></source-rating>');
         end loop;
         cwms_util.append(l_text, '</source-ratings>');
      when l_is_transitional then
         -----------------------
         -- transitional only --
         -----------------------
         cwms_util.append(l_text, '<select>');
         if l_clone.conditions is not null then
            declare
               l_condition logic_expr_t;
            begin
               for i in 1..l_clone.conditions.count loop
                  l_condition := l_clone.conditions(i);
                  cwms_util.append(l_text, '<case position="'
                  ||i
                  ||'"><when>'
                  ||regexp_replace(regexp_replace(l_condition.to_xml_text, 'ARG90(\d+)', 'R\1'), 'ARG(\d+)', 'I\1')
                  ||'</when><then>'
                  ||regexp_replace(regexp_replace(cwms_util.to_algebraic(l_clone.evaluations(i)), 'ARG90(\d+)', 'R\1'), 'ARG(\d+)', 'I\1')
                  ||'</then></case>');
               end loop;
            end;
            cwms_util.append(l_text, '<default>'
            ||regexp_replace(regexp_replace(cwms_util.to_algebraic(l_clone.evaluations(l_clone.evaluations.count)), 'ARG90(\d+)', 'R\1'), 'ARG(\d+)', 'I\1')
            ||'</default>');
         end if;
         cwms_util.append(l_text, '</select>');
         if l_clone.source_ratings is not null then
            cwms_util.append(l_text, '<source-ratings>');
            for i in 1..l_clone.source_ratings.count loop
               cwms_util.append(l_text, '<rating-spec-id position="'
               ||i
               ||'">'
               ||l_clone.source_ratings(i)
               ||'</rating-spec-id>');
            end loop;
            cwms_util.append(l_text, '</source-ratings>');
         end if;
      else
         -------------------
         -- concrete only --
         -------------------
         if l_clone.formula is null then
            if l_clone.rating_info is null then
               cwms_util.append(l_text, '<rating-points/>');
            else
               cwms_util.append(l_text, l_clone.rating_info.to_clob);
               if l_clone.rating_info.extension_values is not null then
                  cwms_util.append(l_text, l_clone.rating_info.to_clob(p_is_extension=>true));
               end if;
            end if;
         else
            cwms_util.append(l_text, '<formula>'||regexp_replace(upper(l_clone.formula), 'ARG(\d+)', 'I\1')||'</formula>');
         end if;
      end case;
      cwms_util.append(l_text, '</'||l_rating_tag||'>');
      dbms_lob.close(l_text);
      return l_text;
   end;

   member function to_xml(
      self         in out nocopy rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return xmltype
   is
   begin
      return xmltype(self.to_clob(p_timezone, p_units, p_vert_datum));
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
            case
            when self.rating_info is not null then
               ------------------
               -- table rating --
               ------------------
               if l_template is null then
                  l_rating_spec := rating_spec_t(rating_spec_id, office_id);
                  l_template := rating_template_t(office_id, l_rating_spec.template_id);
               end if;
               l_results(j) := self.rating_info.rate(l_ind_set, 1, l_template.ind_parameters);
            when self.formula is not null then
               --------------------
               -- formula rating --
               --------------------
               l_results(j) := cwms_util.eval_tokenized_expression(formula_tokens, l_ind_set);
            else
               cwms_err.raise('ERROR', 'No rating information');
            end case;
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

   member function rate(
      p_values      in  double_tab_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t
   is
      type rating_values_t     is record(ind_vals double_tab_tab_t, dep_vals double_tab_t);
      type rating_values_tab_t is table of rating_values_t;
      type boolean_tab_t       is table of boolean;
      l_rating_values       rating_values_tab_t;
      l_is_rating           boolean;
      l_rating              pls_integer;
      l_ind_val             pls_integer;
      l_count               pls_integer;
      l_rating_part         varchar2(500);
      l_units_part          varchar2(50);
      l_factor              binary_double;
      l_offset              binary_double;
      l_tokens              str_tab_t;
      l_results             double_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if self.connections is null then
         cwms_err.raise('ERROR', 'Method is only valid for virtual ratings');
      end if;
      l_count := self.get_ind_parameter_count;
      if p_values is null or p_values.count != l_count then
         cwms_err.raise(
            'ERROR',
            'Expected '||l_count||' sets of input data, got '
            ||case
              when p_values is null then 0
              else p_values.count
              end);
      end if;
      if p_units is null or p_units.count != l_count+1 then
         cwms_err.raise(
            'ERROR',
            'Expected '||(l_count+1)||' units, got '
            ||case
              when p_units is null then 0
              else p_units.count
              end);
      end if;
      for i in 2..p_values.count loop
         if p_values(i).count != p_values(1).count then
            cwms_err.raise(
               'ERROR',
               'Input data sets have differing lengths');
         end if;
      end loop;

      l_rating_values := rating_values_tab_t();
      l_rating_values.extend(self.source_ratings.count);
      ------------------------------------------------------------------------------------------
      -- for each source rating, populate its inputs and perform the rating to get its output --
      ------------------------------------------------------------------------------------------
      for i in 1..self.source_ratings.count loop
         ----------------------------------------------------------------------
         -- determine if this source rating is a rating spec or an expresion --
         ----------------------------------------------------------------------
         parse_source_rating(
            l_is_rating,
            l_rating_part,
            l_units_part,
            self.source_ratings(i));
         ---------------------------------------------
         -- populate the data for the source rating --
         ---------------------------------------------
         l_rating_values(i).ind_vals := double_tab_tab_t();
         l_rating_values(i).ind_vals.extend(self.connections_map(i).ind_params.count);
         ---------------------------------------------------
         -- populate any inputs on independent parameters --
         ---------------------------------------------------
         for j in 1..self.connections_map(i).ind_params.count loop
            if self.connections_map(i).ind_params(j) is not null then
               self.parse_connection_part(l_rating, l_ind_val, self.connections_map(i).ind_params(j));
               if l_rating < i then
                  if l_rating = 0 then
                     begin
                        select factor,
                               offset
                          into l_factor,
                               l_offset
                          from cwms_unit_conversion
                         where from_unit_id = cwms_util.get_unit_id(p_units(l_ind_val), self.office_id)
                           and to_unit_id = cwms_util.get_unit_id(self.connections_map(i).units(j));
                     exception
                        when no_data_found then
                           cwms_err.raise(
                              'ERROR',
                              'Cannot convert from input '||l_ind_val||' unit of '||p_units(l_ind_val)
                              ||' to rating '||i||' independent parameter '||j||' unit of '||self.connections_map(i).units(j));
                     end;
                     select column_value * l_factor + l_offset
                       bulk collect
                       into l_rating_values(i).ind_vals(j)
                       from table(p_values(l_ind_val));
                  else
                     if l_ind_val = 0 then
                        l_factor := self.connections_map(l_rating).factors(self.connections_map(l_rating).factors.count);
                        l_offset := self.connections_map(l_rating).offsets(self.connections_map(l_rating).offsets.count);
                        select column_value * l_factor + l_offset
                          bulk collect
                          into l_rating_values(i).ind_vals(j)
                          from table(l_rating_values(l_rating).dep_vals);
                     else
                        l_factor := self.connections_map(l_rating).factors(l_ind_val);
                        l_offset := self.connections_map(l_rating).offsets(l_ind_val);
                        select column_value * l_factor + l_offset
                          bulk collect
                          into l_rating_values(i).ind_vals(j)
                          from table(l_rating_values(l_rating).ind_vals(l_ind_val));
                     end if;
                  end if;
                  if l_rating_values(i).ind_vals(j) is null or l_rating_values(i).ind_vals(j).count = 0 then
                     cwms_err.raise(
                        'ERROR',
                        'No values found at '
                        ||self.connections_map(i).ind_params(j)
                        ||' to populate R'
                        ||i
                        ||'I'
                        ||j);
                  end if;
               end if;
            end if;
         end loop;
         -------------------------------------------------
         -- populate any inputs on dependent parameters --
         -------------------------------------------------
         if self.connections_map(i).dep_param is not null then
            parse_connection_part(l_rating, l_ind_val, self.connections_map(i).dep_param);
            if l_rating < i then
               if l_rating = 0 then
                  begin
                     select factor,
                            offset
                       into l_factor,
                            l_offset
                       from cwms_unit_conversion
                      where from_unit_id = cwms_util.get_unit_id(p_units(l_ind_val), self.office_id)
                        and to_unit_id = cwms_util.get_unit_id(self.connections_map(i).units(self.connections_map(i).units.count));
                  exception
                     when no_data_found then
                        cwms_err.raise(
                           'ERROR',
                           'Cannot convert from input '||l_ind_val||' unit of '||p_units(l_ind_val)
                           ||' to rating '||i||' dependent parameter unit of '||self.connections_map(i).units(self.connections_map(i).units.count));
                  end;
                  select column_value * l_factor + l_offset
                    bulk collect
                    into l_rating_values(i).dep_vals
                    from table(p_values(l_ind_val));
               else
                  if l_ind_val = 0 then
                     l_factor := self.connections_map(l_rating).factors(self.connections_map(l_rating).factors.count);
                     l_offset := self.connections_map(l_rating).offsets(self.connections_map(l_rating).offsets.count);
                     select column_value * l_factor + l_offset
                       bulk collect
                       into l_rating_values(i).dep_vals
                       from table(l_rating_values(l_rating).dep_vals);
                  else
                     l_factor := self.connections_map(l_rating).factors(l_ind_val);
                     l_offset := self.connections_map(l_rating).offsets(l_ind_val);
                     select column_value * l_factor + l_offset
                       bulk collect
                       into l_rating_values(i).dep_vals
                       from table(l_rating_values(l_rating).ind_vals(l_ind_val));
                  end if;
               end if;
               if l_rating_values(i).dep_vals is null then
                  cwms_err.raise(
                     'ERROR',
                     'No values found at '
                     ||self.connections_map(i).dep_param
                     ||' to populate R'
                     ||i
                     ||'D');
               end if;
            end if;
         end if;
         ----------------------------------------------------------------------
         -- verify that only the output (ind or dep parameter) has no values --
         ----------------------------------------------------------------------
         select count(*)
           into l_count
           from table(l_rating_values(i).ind_vals)
          where column_value is null;
         if l_count = 0 then
            if l_rating_values(i).dep_vals is not null then
               cwms_err.raise(
                  'ERROR',
                  'Source rating '
                  ||i
                  ||' is over-connected. Values for all independent and dependent parameters are specified');
            end if;
         else
            if l_count > 1 or (l_count = 1 and l_rating_values(i).dep_vals is null) then
               cwms_err.raise(
                  'ERROR',
                  'Soure rating '
                  ||i
                  ||' is under-connected. Values for more than one independent and/or dependent parameters are unspecified');
            end if;
         end if;
         ------------------------
         -- perform the rating --
         ------------------------
         if l_rating_values(i).dep_vals is null then
            if l_is_rating then
               l_rating_values(i).dep_vals := cwms_rating.rate_f(
                  p_rating_spec => l_rating_part,
                  p_values      => l_rating_values(i).ind_vals,
                  p_units       => self.connections_map(i).units,
                  p_round       => case when i = self.source_ratings.count then p_round else 'F' end,
                  p_value_times => p_value_times,
                  p_rating_time => p_rating_time,
                  p_time_zone   => p_time_zone,
                  p_office_id   => self.office_id);
            else
               l_tokens := cwms_util.split_text(l_rating_part, ' '); -- already in RPN from
               l_count := l_rating_values(i).ind_vals(1).count;
               l_rating_values(i).dep_vals := double_tab_t();
               l_rating_values(i).dep_vals.extend(l_count);
               for j in 1..l_count loop
                  l_rating_values(i).dep_vals(j) := cwms_util.eval_tokenized_expression(
                     l_tokens,
                     cwms_util.get_column(l_rating_values(i).ind_vals, j));
               end loop;
            end if;
            if l_rating_values(i).dep_vals is null or l_rating_values(i).dep_vals.count = 0 then
               cwms_err.raise(
                  'ERROR',
                  'Source rating '||i||' produced no values');
            end if;
         else
            if l_is_rating then
               l_rating_values(i).ind_vals(1) := cwms_rating.reverse_rate_f(
                  p_rating_spec => l_rating_part,
                  p_values      => l_rating_values(i).dep_vals,
                  p_units       => self.connections_map(i).units,
                  p_round       => case when i = self.source_ratings.count then p_round else 'F' end,
                  p_value_times => p_value_times,
                  p_rating_time => p_rating_time,
                  p_time_zone   => p_time_zone,
                  p_office_id   => self.office_id);
            else
               cwms_err.raise('ERROR', 'Cannot reverse through a rating expression');
            end if;
            if l_rating_values(i).ind_vals(1) is null or l_rating_values(i).ind_vals(1).count = 0 then
               cwms_err.raise(
                  'ERROR',
                  'Source rating '||i||' produced no values');
            end if;
         end if;
      end loop;
      ------------------------------------------------------
      -- put the results in the requested unit and return --
      ------------------------------------------------------
      l_count := self.connections_map.count;
      if self.connections_map(self.source_ratings.count).dep_param is null then
         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(self.connections_map(l_count).units(self.connections_map(l_count).units.count))
            and to_unit_id = cwms_util.get_unit_id(p_units(p_units.count));

         select column_value * l_factor + l_offset
           bulk collect
           into l_results
           from table(l_rating_values(l_count).dep_vals);
      else
         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(self.connections_map(l_count).units(1))
            and to_unit_id = cwms_util.get_unit_id(p_units(p_units.count));

         select column_value * l_factor + l_offset
           bulk collect
           into l_results
           from table(l_rating_values(l_count).ind_vals(1));
      end if;
      return l_results;
   end rate;

   member function rate(
      p_values          in double_tab_tab_t,
      p_value_times_utc in date_table_type,
      p_rating_time_utc in date)
   return double_tab_t
   is
      type arg_hash_t is table of pls_integer index by varchar2(8);
      l_arg_names   str_tab_t;
      l_tokens      str_tab_t;
      l_inputs      double_tab_t;
      l_arg_hash    arg_hash_t;
      l_arg_num     pls_integer;
      l_results     double_tab_t;
      l_value_times date_table_type;

      function tabify(p_input in double_tab_t) return double_tab_tab_t
      is
         ll_results double_tab_tab_t;
      begin
         select double_tab_t(column_value)
           bulk collect
           into ll_results
           from table(p_input);

         return ll_results;
      end tabify;

      function test_condition(p_input in pls_integer, p_condition in pls_integer) return boolean
      is
      begin
         return self.conditions(p_condition).evaluate(cwms_util.get_column(p_values, p_input));
      end test_condition;

      function evaluate(p_input in pls_integer, p_evaluation in pls_integer) return binary_double
      is
      begin
         -------------------------------
         -- populate the input values --
         -------------------------------
         select distinct
                replace(column_value, '-', null)
           bulk collect
           into l_arg_names
           from table(self.evaluations(p_evaluation))
          where instr(replace(column_value, '-', null), 'ARG') = 1
          order by 1;

        l_inputs := double_tab_t();
        l_inputs.extend(l_arg_names.count);
         for i in 1..l_arg_names.count loop
            l_arg_hash(l_arg_names(i)) := i;
            l_arg_num := to_number(substr(l_arg_names(i), 4));
            if l_arg_num > 900 then
               ------------
               -- rating --
               ------------
               l_inputs(i) := cwms_rating.rate_f(
                  p_rating_spec => self.source_ratings(to_number(substr(l_arg_names(i), 6))),
                  p_values      => tabify(cwms_util.get_column(p_values, p_input)),
                  p_units       => cwms_util.split_text(replace(self.native_units, ';', ','), ','),
                  p_round       => 'F',
                  p_value_times => case
                                   when p_value_times_utc is null then null
                                   else date_table_type(p_value_times_utc(p_input))
                                   end,
                  p_rating_time => p_rating_time_utc,
                  p_time_zone   => 'UTC',
                  p_office_id   => self.office_id)(1);
            else
               -----------
               -- input --
               -----------
              l_inputs(i) := p_values(i)(p_input);
            end if;
         end loop;
         -------------------------------------------------------
         -- modify the tokens to reference the correct inputs --
         -------------------------------------------------------
         l_tokens := str_tab_t();
         l_tokens.extend(self.evaluations(p_evaluation).count);
         for i in 1..l_tokens.count loop
            if instr(self.evaluations(p_evaluation)(i), 'ARG') = 1 then
               l_tokens(i) := 'ARG'||l_arg_hash(self.evaluations(p_evaluation)(i));
            else
               l_tokens(i) := self.evaluations(p_evaluation)(i);
            end if;
         end loop;
         -----------------------------------------
         -- evaluate the tokens with the inputs --
         -----------------------------------------
         return cwms_util.eval_tokenized_expression(l_tokens, l_inputs);
      end evaluate;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if self.evaluations is null then
         cwms_err.raise('ERROR', 'Method is only valid for transitional ratings');
      end if;
      if p_values is not null then
         if p_values.count != self.get_ind_parameter_count then
            cwms_err.raise(
               'ERROR',
               'Expected '||self.get_ind_parameter_count||' sets of input data, got '
               ||p_values.count);
         end if;
         for i in 2..p_values.count loop
            if p_values(i).count != p_values(1).count then
               cwms_err.raise(
                  'ERROR',
                  'Input data sets have differing lengths');
            end if;
         end loop;

         l_results := double_tab_t();
         l_results.extend(p_values(1).count);
         for i in 1..p_values(1).count loop
            if self.conditions is not null then
               for j in 1..self.conditions.count loop
                  if test_condition(i, j) then
                     l_results(i) := evaluate(i, j);
                     exit;
                  end if;
               end loop;
            end if;
            if l_results(i) is null then
               l_results(i) := evaluate(i, self.evaluations.count);
            end if;
         end loop;
      end if;
      return l_results;
   end rate;

   member function reverse
   return rating_t
   is
      l_clone    rating_t;
      l_spec     rating_spec_t;
      l_template rating_template_t;
      l_changed  boolean := false;
      l_parts    str_tab_t;
   begin
      if self.rating_info is null then
         cwms_err.raise('ERROR', 'Cannot reverse a non-table-based rating');
      end if;
      ------------------------------------------------------------------
      -- clone the rating, reversing independent and dependent values --
      ------------------------------------------------------------------
      l_clone := rating_t(self);
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

   member function reverse_rate(
      p_values      in  double_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t
   is
      type rating_values_t     is record(ind_vals double_tab_t, dep_vals double_tab_t);
      type rating_values_tab_t is table of rating_values_t;
      type boolean_tab_t       is table of boolean;
      l_rating_values       rating_values_tab_t;
      l_is_rating           boolean;
      l_rating              pls_integer;
      l_ind_val             pls_integer;
      l_count               pls_integer;
      l_rating_part         varchar2(500);
      l_units_part          varchar2(50);
      l_factor              binary_double;
      l_offset              binary_double;
      l_results             double_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if self.source_ratings is null then
         cwms_err.raise('ERROR', 'Method is only valid for virtual ratings');
      end if;
      if self.get_ind_parameter_count != 1 then
         cwms_err.raise(
            'ERROR',
            'Cannot reverse through a multiple independent paramter rating');
      end if;
      if p_units is null or p_units.count != 2 then
         cwms_err.raise(
            'ERROR',
            'Expected 2 units, got '
            ||case
              when p_units is null then 0
              else p_units.count
              end);
      end if;

      l_rating_values := rating_values_tab_t();
      l_rating_values.extend(self.source_ratings.count);
      ------------------------------------------------------------------------------------------
      -- for each source rating, populate its inputs and perform the rating to get its output --
      ------------------------------------------------------------------------------------------
      for i in reverse 1..self.source_ratings.count loop
         ----------------------------------------------------------------------
         -- determine if this source rating is a rating spec or an expresion --
         ----------------------------------------------------------------------
         parse_source_rating(
            l_is_rating,
            l_rating_part,
            l_units_part,
            self.source_ratings(i));
         if not l_is_rating then
            cwms_err.raise(
               'ERROR',
               'Cannot reverse rate a virtual rating that contains a rating expression');
         end if;
         ---------------------------------------------
         -- populate the data for the source rating --
         ---------------------------------------------
         if self.connections_map(i).ind_params.count != 1 then
            cwms_err.raise(
               'ERROR',
               'Cannot reverse through a multiple independent paramter rating');
         end if;
         ---------------------------------------------------
         -- populate any inputs on independent parameters --
         ---------------------------------------------------
         case
         when self.connections_map(i).ind_params(1) is null then
            if i = self.source_ratings.count then
               begin
                  select factor,
                         offset
                    into l_factor,
                         l_offset
                    from cwms_unit_conversion
                   where from_unit_id = cwms_util.get_unit_id(p_units(2), self.office_id)
                     and to_unit_id = cwms_util.get_unit_id(self.connections_map(i).units(1), self.office_id);
               exception
                  when no_data_found then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot convert from input unit of '||p_units(2)
                        ||' to rating '||i||' independent parameter unit of '||self.connections_map(i).units(1));
               end;
               select column_value * l_factor + l_offset
                 bulk collect
                 into l_rating_values(i).ind_vals
                 from table(p_values);
            else
               cwms_err.raise(
                  'ERROR',
                  'Unexpected null connection found at R'||i||'I1');
            end if;
         when self.connections_map(i).ind_params(1) = 'I1' then
            null; -- output of virtual rating
         else
            parse_connection_part(l_rating, l_ind_val, self.connections_map(i).ind_params(1));
            if l_rating > i then
               if l_ind_val = 0 then
                  l_factor := self.connections_map(l_rating).factors(2);
                  l_offset := self.connections_map(l_rating).offsets(2);
                  select column_value * l_factor + l_offset
                    bulk collect
                    into l_rating_values(i).ind_vals
                    from table(l_rating_values(l_rating).dep_vals);
               else
                  l_factor := self.connections_map(l_rating).factors(1);
                  l_offset := self.connections_map(l_rating).offsets(1);
                  select column_value * l_factor + l_offset
                    bulk collect
                    into l_rating_values(i).ind_vals
                    from table(l_rating_values(l_rating).ind_vals);
               end if;
               if l_rating_values(i).ind_vals is null then
                  cwms_err.raise(
                     'ERROR',
                     'No values found at '
                     ||self.connections_map(i).ind_params(1)
                     ||' to populate R'
                     ||i
                     ||'I1');
               end if;
            end if;
         end case;
         -------------------------------------------------
         -- populate any inputs on dependent parameters --
         -------------------------------------------------
         case
         when self.connections_map(i).dep_param is null then
            if i = self.source_ratings.count then
               begin
                  select factor,
                         offset
                    into l_factor,
                         l_offset
                    from cwms_unit_conversion
                   where from_unit_id = cwms_util.get_unit_id(p_units(2), self.office_id)
                     and to_unit_id = cwms_util.get_unit_id(self.connections_map(i).units(2));
               exception
                  when no_data_found then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot convert from input unit of '||p_units(2)
                        ||' to rating '||i||' dependent parameter unit of '||cwms_util.get_unit_id(self.connections_map(i).units(2)));
               end;
               select column_value * l_factor + l_offset
                 bulk collect
                 into l_rating_values(i).dep_vals
                 from table(p_values);
            else
               cwms_err.raise(
                  'ERROR',
                  'Unexpected null connection found at R'||i||'D');
            end if;
         when self.connections_map(i).dep_param = 'I1' then
            null; -- output of virtual rating
         else
            parse_connection_part(l_rating, l_ind_val, self.connections_map(i).dep_param);
            if l_ind_val = 0 then
               l_factor := self.connections_map(l_rating).factors(2);
               l_offset := self.connections_map(l_rating).offsets(2);
               select column_value * l_factor + l_offset
                 bulk collect
                 into l_rating_values(i).dep_vals
                 from table(l_rating_values(l_rating).dep_vals);
            else
               l_factor := self.connections_map(l_rating).factors(1);
               l_offset := self.connections_map(l_rating).offsets(2);
               select column_value * l_factor + l_offset
                 bulk collect
                 into l_rating_values(i).dep_vals
                 from table(l_rating_values(l_rating).ind_vals);
            end if;
            if l_rating_values(i).dep_vals is null then
               cwms_err.raise(
                  'ERROR',
                  'No values found at '
                  ||self.connections_map(i).dep_param
                  ||' to populate R'
                  ||i
                  ||'D');
            end if;
         end case;
         ----------------------------------------------------------------------
         -- verify that only the output (ind or dep parameter) has no values --
         ----------------------------------------------------------------------
         l_count := 0;
         if l_rating_values(i).ind_vals is not null then l_count := l_count + 1; end if;
         if l_rating_values(i).dep_vals is not null then l_count := l_count + 1; end if;
         if l_count = 0 then
            cwms_err.raise(
               'ERROR',
               'Soure rating '
               ||i
               ||' is under-connected. No independent or dependent parameter values are specified');
         elsif l_count = 2 then
            cwms_err.raise(
               'ERROR',
               'Source rating '
               ||i
               ||' is over-connected. Values for independent and dependent parameters are specified');
         end if;
         ------------------------
         -- perform the rating --
         ------------------------
         if l_rating_values(i).dep_vals is null then
            l_rating_values(i).dep_vals := cwms_rating.rate_f(
               p_rating_spec => l_rating_part,
               p_values      => double_tab_tab_t(l_rating_values(i).ind_vals),
               p_units       => self.connections_map(i).units,
               p_round       => case when i = 1 then p_round else 'F' end,
               p_value_times => p_value_times,
               p_rating_time => p_rating_time,
               p_time_zone   => p_time_zone,
               p_office_id   => self.office_id);
         else
            l_rating_values(i).ind_vals := cwms_rating.reverse_rate_f(
               p_rating_spec => l_rating_part,
               p_values      => l_rating_values(i).dep_vals,
               p_units       => self.connections_map(i).units,
               p_round       => case when i = 1 then p_round else 'F' end,
               p_value_times => p_value_times,
               p_rating_time => p_rating_time,
               p_time_zone   => p_time_zone,
               p_office_id   => self.office_id);
         end if;
      end loop;
      ------------------------------------------------------
      -- put the results in the requested unit and return --
      ------------------------------------------------------
      if self.connections_map(1).dep_param = 'I1' then
         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(self.connections_map(1).units(2))
            and to_unit_id = cwms_util.get_unit_id(p_units(1));

         select column_value * l_factor + l_offset
           bulk collect
           into l_results
           from table(l_rating_values(l_count).dep_vals);
      else
         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(self.connections_map(1).units(1))
            and to_unit_id = cwms_util.get_unit_id(p_units(1));

         select column_value * l_factor + l_offset
           bulk collect
           into l_results
           from table(l_rating_values(l_count).ind_vals);
      end if;
      return l_results;
   end;

   member function get_ind_parameters
   return str_tab_t
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(rating_spec_id, cwms_rating.separator1);
      l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      l_parts := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      return l_parts;
   end;

   member function get_ind_parameter(
      p_position in integer)
   return varchar2
   is
      l_parts str_tab_t;
   begin
      l_parts := get_ind_parameters;
      if p_position is null or not p_position between 1 and l_parts.count then
         cwms_err.raise(
            'ERROR',
            'Expected position in range 1..'
            ||l_parts.count
            ||', got '
            ||nvl(p_position, 'NULL'));
      end if;
      return l_parts(p_position);
   end;

   member function get_dep_parameter
   return varchar2
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(rating_spec_id, cwms_rating.separator1);
      l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      return l_parts(2);
   end;

   member function get_date(p_timestr in varchar2) return date
   is
      l_date  date;
      l_parts str_tab_t;
      l_tzstr varchar2(32);
   begin
      l_date  := trunc(cwms_util.to_timestamp(substr(p_timestr, 1, 19)), 'MI');
      l_tzstr := substr(p_timestr, 20);
      ------------------
      -- shift to UTC --
      ------------------
      if l_tzstr is null then
         ----------------------------
         -- assume local time zone --
         ----------------------------
         l_parts := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
         l_tzstr := cwms_loc.get_local_timezone(l_parts(1), self.office_id);
         if l_tzstr is null then
            cwms_err.raise(
               'ERROR',
               'Rating for '
               ||self.office_id||'/'||l_parts(1)
               ||' specifies an effective date without a time zone, but no local time zone is set.');
         end if;
      else
         if l_tzstr = 'Z' then
            l_tzstr := 'UTC';
         else
            l_tzstr := 'Etc/GMT'
            ||case substr(l_tzstr, 1, 1)
                 when '+' then '-' || to_number(substr(l_tzstr, 2, 2))
                 when '-' then '+' || to_number(substr(l_tzstr, 2, 2))
              end;
         end if;
      end if;
      l_date := cwms_util.change_timezone(l_date, l_tzstr, 'UTC');
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
      l_location_id             varchar2(57);
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
         --------------------------
         -- match effective date --
         --------------------------
         ----------------------
         -- concrete ratings --
         ----------------------
         begin
            select rating_code
              into l_rating_code
              from at_rating
             where rating_spec_code = l_rating_spec_code
               and effective_date = l_effective_date;
         exception
            when no_data_found then null;
         end;
         if l_rating_code is null then
            --------------------------
            -- transitional ratings --
            --------------------------
            begin
               select transitional_rating_code
                 into l_rating_code
                 from at_transitional_rating
                where rating_spec_code = l_rating_spec_code
                  and effective_date = l_effective_date;
            exception
               when no_data_found then null;
            end;
         end if;
         if l_rating_code is null then null;
            ---------------------
            -- virtual ratings --
            ---------------------
            begin
               select virtual_rating_code
                 into l_rating_code
                 from at_virtual_rating
                where rating_spec_code = l_rating_spec_code
                  and effective_date = l_effective_date;
            exception
               when no_data_found then null;
            end;
         end if;
      else
         ---------------------------------
         -- effective on specified date --
         ---------------------------------
         ----------------------
         -- concrete ratings --
         ----------------------
         begin
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
         exception
            when no_data_found then null;
         end;
         if l_rating_code is null then
            --------------------------
            -- transitional ratings --
            --------------------------
            begin
               select transitional_rating_code
                 into l_rating_code
                 from at_transitional_rating
                where rating_spec_code = l_rating_spec_code
                  and effective_date =
                      ( select max(effective_date)
                          from at_rating
                         where rating_spec_code = l_rating_spec_code
                           and effective_date <= l_effective_date
                      );
            exception
               when no_data_found then null;
            end;
         end if;
         if l_rating_code is null then null;
            ---------------------
            -- virtual ratings --
            ---------------------
            begin
               select virtual_rating_code
                 into l_rating_code
                 from at_virtual_rating
                where rating_spec_code = l_rating_spec_code
                  and effective_date =
                      ( select max(effective_date)
                          from at_rating
                         where rating_spec_code = l_rating_spec_code
                           and effective_date <= l_effective_date
                      );
            exception
               when no_data_found then null;
            end;
         end if;
      end if;

      return l_rating_code;
   end;
end;
/
show errors;

create or replace type body rating_ind_parameter_t
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
      l_position             number(1);
      l_value                binary_double;
      l_ind_value            binary_double;
      l_last_ind_value       binary_double;
      l_dep_value            binary_double;
      l_note_text            varchar2(64);
      l_rating_value         rating_value_t;
      l_rating_values        rating_value_tab_t;
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
      function get_node(pp_xml in xmltype, p_path in varchar2) return xmltype is
      begin
         return cwms_util.get_xml_node(pp_xml, p_path);
      end;
      function get_text(pp_xml in xmltype, p_path in varchar2) return varchar2 is
      begin
         return cwms_util.get_xml_text(pp_xml, p_path);
      end;
      function get_number(pp_xml in xmltype, p_path in varchar2) return number is
      begin
         return cwms_util.get_xml_number(pp_xml, p_path);
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
         ll_rating_value_tab_id varchar2(32767);
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
                  ll_rating_value_tab_id := p_parent_id || rec.ind_value;
               else
                  ll_rating_value_tab_id := p_parent_id || cwms_rating.separator3 || rec.ind_value;
               end if;
               if l_rating_value_tab.exists(ll_rating_value_tab_id) then
                  -------------------------------------------------------
                  -- attach the pre-built rating_value_tab_t of values --
                  -------------------------------------------------------
                  l_rating_param.rating_values := l_rating_value_tab(ll_rating_value_tab_id);
               else
                  --------------------------------------------------------------------------------------------
                  -- create a new rating_value_tab_t from info below the current position/value combination --
                  --------------------------------------------------------------------------------------------
                  l_rating_param.rating_values := build_rating(ll_rating_value_tab_id, p_position+1);
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
         l_parts := cwms_util.split_text(get_text(p_xml, '/*/rating-spec-id'), cwms_rating.separator1);
         l_parts := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
         l_ind_params := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      exception
         when others then
            cwms_err.raise('ERROR', 'Cannot determine rating independent parameter(s)');
      end;
      begin
         l_parts := cwms_util.split_text(get_text(p_xml, '/*/units-id'), cwms_rating.separator2);
         l_ind_units := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      exception
         when others then
            cwms_err.raise('ERROR', 'Cannot determine rating independent unit(s)');
      end;
      <<value_types>>
      for i in 1..l_value_type.count loop
         ----------------------------------------------------------------
         -- for each value type in 'rating-points', 'extension-points' --
         ----------------------------------------------------------------
         l_processed_points := false;
         <<rating_points>>
         for j in 1..9999999 loop
            ------------------------------------------------------------
            -- for each <rating-points> or <extension-points> element --
            ------------------------------------------------------------
            l_rating_points := get_node(p_xml, '/*/'||l_value_type(i)||'['||j||']');
            exit rating_points when l_rating_points is null;
            if j > 1 and l_ind_params.count = 1 then
               cwms_err.raise(
                  'ERROR',
                  'Multiple <'||l_value_type(i)||'> elements are not allowed in a single independent parameter rating.');
            end if;
            l_processed_points := true;
            l_position := 0;
            l_rating_value_tab_id := l_value_type(i)||'=';
            <<other_ind>>
            for k in 1..9999999 loop
               ----------------------------------
               -- for each <other-ind> element --
               ----------------------------------
               l_other_ind := get_node(l_rating_points, '/'||l_value_type(i)||'/other-ind['||k||']');
               if l_other_ind is null then
                  if k != l_ind_params.count then
                     cwms_err.raise(
                        'ERROR',
                        'Each <'
                        ||l_value_type(i)
                        ||'> element in a '
                        ||l_ind_params.count
                        ||' independent parameter rating must have '
                        ||l_ind_params.count-1
                        ||' <other-ind> elements.');
                  else
                     exit other_ind;
                  end if;
               else
                  if l_ind_params.count = 1 then
               cwms_err.raise(
                  'ERROR',
                  '<other-ind> elements are not allowed in a single independent parameter rating.');
                  end if;
               end if;
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
            end loop other_ind;
            l_last_ind_value := null;
            l_rating_values  := rating_value_tab_t();
            <<points>>
            for k in 1..9999999 loop
               ------------------------------
               -- for each <point> element --
               ------------------------------
               l_point := get_node(l_rating_points, '/'||l_value_type(i)||'/point['||k||']');
               exit points when l_point is null;
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
            end loop points;
            --------------------------------------------------------------------------------
            -- index the new rating_value_t by the rating value table id contructed above --
            --------------------------------------------------------------------------------
            l_rating_value_tab(l_rating_value_tab_id) := l_rating_values;
         end loop rating_points;
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
      end loop value_types;
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
         null; -- allow null rating values
--         ----------------------------------------------
--         -- create a dummy table if none is supplied --
--         ----------------------------------------------
--         self.rating_values := rating_value_tab_t(rating_value_t(0, 0, null, null));
----       cwms_err.raise(
----          'ERROR',
----          'Rating independent parameter '||p_parameter_position||' has no values');
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
            l_ind_unit_id := cwms_util.get_unit_id(l_parts(1));
            l_dep_unit_id := cwms_util.get_unit_id(l_parts(2));
            begin
            select factor,
                   offset
              into l_dep_factor,
                   l_dep_offset
              from cwms_base_parameter bp,
                   cwms_unit_conversion uc
                where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_dep_param_id))
               and uc.to_unit_code = bp.unit_code
               and uc.from_unit_id = l_dep_unit_id;
            exception
               when no_data_found then
                  cwms_err.raise(
                     'ERROR',
                     'Don''t know how to convert '
                     ||l_dep_unit_id
                     ||' to database unit for parameter '
                     ||l_dep_param_id);
            end;
         else
            l_parts := cwms_util.split_text(p_parameters_id, cwms_rating.separator3);
            l_ind_param_id := l_parts(1);
            l_parts := cwms_util.split_text(p_units_id, cwms_rating.separator3);
            l_ind_unit_id := cwms_util.get_unit_id(l_parts(1));
            l_remaining_parameters_id := substr(p_parameters_id, instr(p_parameters_id, cwms_rating.separator3) + 1);
            l_remaining_units_id := substr(p_units_id, instr(p_units_id, cwms_rating.separator3) + 1);
         end if;
         begin
         select factor,
                offset
           into l_ind_factor,
                l_ind_offset
           from cwms_base_parameter bp,
                cwms_unit_conversion uc
             where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(l_ind_param_id))
            and uc.to_unit_code = bp.unit_code
            and uc.from_unit_id = l_ind_unit_id;
         exception
            when no_data_found then
               cwms_err.raise(
                  'ERROR',
                  'Don''t know how to convert '
                  ||l_ind_unit_id
                  ||' to database unit for parameter '
                  ||l_ind_param_id);
         end;
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
      l_rating_ind_param_code number(14);
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
      if p_is_extension then
         for i in 1..self.extension_values.count loop
            if i = 1 then
               ----------------------------
               -- output the opening tag --
               ----------------------------
               cwms_util.append(l_text, '<extension-points>');
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
               ||cwms_rounding.round_dt_f(self.extension_values(i).ind_value, '9999999999')
               ||'</ind><dep>'
               ||cwms_rounding.round_dt_f(self.extension_values(i).dep_value, '9999999999')
               ||'</dep>'
               ||case self.extension_values(i).note_id is not null
                    when true then '<note>'||self.extension_values(i).note_id||'</note>'
                 end
               ||'</point>');
            if i = self.extension_values.count then
               ----------------------------
               -- output the closing tag --
               ----------------------------
               cwms_util.append(l_text, '</extension-points>');
            end if;
         end loop;
      else
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
                  cwms_util.append(l_text, '<rating-points>');
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
            cwms_util.append(l_text, '</rating-points>');
         end if;
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

   overriding member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer)
   is
   begin
      if self.rating_values is not null then
         for i in 1..self.rating_values.count loop
            case p_depth
               when  1 then
                  self.rating_values(i).ind_value := self.rating_values(i).ind_value + p_offset;
               when -1 then
                  if self.rating_values(i).dep_value is not null then
                     self.rating_values(i).dep_value := self.rating_values(i).dep_value + p_offset;
                  else
                     self.rating_values(i).dep_rating_ind_param.add_offset(p_offset, -1);
                  end if;
               else
                  self.rating_values(i).dep_rating_ind_param.add_offset(p_offset, p_depth - 1);
            end case;
         end loop;
      end if;
      if self.extension_values is not null then
         for i in 1..self.extension_values.count loop
            case p_depth
               when  1 then
                  self.extension_values(i).ind_value := self.extension_values(i).ind_value + p_offset;
               when -1 then
                  self.extension_values(i).dep_value := self.extension_values(i).dep_value + p_offset;
            end case;
         end loop;
      end if;
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
         if l_ind.count = 1 then
            -------------------------------------------------------
            -- just one independent value so we can't use lookup --
            -- also we can ignore extension values               --
            -------------------------------------------------------
            if p_ind_values.count - p_position + 1 = 1 then
               l_result := rating_values(1).dep_value;
            else
               l_result := rating_values(1).dep_rating_ind_param.rate(
                  p_ind_values,
                  p_position+1,
                  p_param_specs);
            end if;
            case
            when p_ind_values(p_position) < l_ind(1) then
               case l_out_range_low_behavior
               when cwms_lookup.method_null        then l_result := null;
               when cwms_lookup.method_error       then cwms_err.raise('ERROR', 'Value '||p_ind_values(p_position)||' is below curve');
               when cwms_lookup.method_linear      then cwms_err.raise('ERROR', 'Cannot extrapolate below curve: curve has only one independent value');
               when cwms_lookup.method_logarithmic then cwms_err.raise('ERROR', 'Cannot extrapolate below curve: curve has only one independent value');
               when cwms_lookup.method_lin_log     then cwms_err.raise('ERROR', 'Cannot extrapolate below curve: curve has only one independent value');
               when cwms_lookup.method_log_lin     then cwms_err.raise('ERROR', 'Cannot extrapolate below curve: curve has only one independent value');
               when cwms_lookup.method_previous    then cwms_err.raise('ERROR', 'No previous value');
               when cwms_lookup.method_next        then null;
               when cwms_lookup.method_nearest     then null;
               when cwms_lookup.method_lower       then cwms_err.raise('ERROR', 'No lower value');
               when cwms_lookup.method_higher      then null;
               when cwms_lookup.method_closest     then null;
               end case;
            when p_ind_values(p_position) > l_ind(1) then
               case l_out_range_high_behavior
               when cwms_lookup.method_null        then l_result := null;
               when cwms_lookup.method_error       then cwms_err.raise('ERROR', 'Value '||p_ind_values(p_position)||' is above curve');
               when cwms_lookup.method_linear      then cwms_err.raise('ERROR', 'Cannot extrapolate above curve: curve has only one independent value');
               when cwms_lookup.method_logarithmic then cwms_err.raise('ERROR', 'Cannot extrapolate above curve: curve has only one independent value');
               when cwms_lookup.method_lin_log     then cwms_err.raise('ERROR', 'Cannot extrapolate above curve: curve has only one independent value');
               when cwms_lookup.method_log_lin     then cwms_err.raise('ERROR', 'Cannot extrapolate above curve: curve has only one independent value');
               when cwms_lookup.method_previous    then null;
               when cwms_lookup.method_next        then cwms_err.raise('ERROR', 'No next value');
               when cwms_lookup.method_nearest     then null;
               when cwms_lookup.method_lower       then null;
               when cwms_lookup.method_higher      then cwms_err.raise('ERROR', 'No higher value');
               when cwms_lookup.method_closest     then null;
               end case;
            else --  p_ind_values(p_position) = l_ind(1)
               case l_in_range_behavior
               when cwms_lookup.method_null        then l_result := null;
               when cwms_lookup.method_error       then cwms_err.raise('ERROR', 'Value '||p_ind_values(p_position)||' matches only independent value in rating');
               when cwms_lookup.method_linear      then null;
               when cwms_lookup.method_logarithmic then null;
               when cwms_lookup.method_lin_log     then null;
               when cwms_lookup.method_log_lin     then null;
               when cwms_lookup.method_previous    then cwms_err.raise('ERROR', 'No previous value');
               when cwms_lookup.method_next        then cwms_err.raise('ERROR', 'No next value');
               when cwms_lookup.method_nearest     then null;
               when cwms_lookup.method_lower       then cwms_err.raise('ERROR', 'No lower value');
               when cwms_lookup.method_higher      then cwms_err.raise('ERROR', 'No higher value');
               when cwms_lookup.method_closest     then null;
               end case;
            end case;
         else
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
                           l_log_hi_val := log(10, l_hi_val);
                           l_log_lo_val := log(10, l_lo_val);
                           if l_log_hi_val is NaN or l_log_hi_val is Infinite or
                              l_log_lo_val is Nan or l_log_lo_val is Infinite
                           then
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
                           end if;
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
      end if;
      return l_result;
   end;

   static function get_rating_ind_parameter_code(
      p_rating_code in number)
   return number
   is
      l_rating_in_parameter_code number(14);
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

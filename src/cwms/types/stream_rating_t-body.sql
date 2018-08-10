create or replace type body stream_rating_t
as
   constructor function stream_rating_t(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
   return self as result
   is
   begin
      (self as rating_t).init(p_rating_code, p_include_points);
      if cwms_util.is_true(p_include_points) then
         self.init(p_rating_code);
      end if;
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
      l_extension_points xmltype;
      l_point            xmltype;
      l_timestr          varchar2(32);
      l_location_id      varchar2(57);
      l_ind_param        varchar2(16);
      l_template_version varchar2(32);
      l_rating_version   varchar2(32);
      l_parts            str_tab_t;
      l_temp             rating_t;
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
      -----------------------------
      -- get the transition date --
      -----------------------------
      l_timestr := get_text(l_xml, '/usgs-stream-rating/transition-start-date');
      if l_timestr is not null then
         self.transition_date := (self as rating_t).get_date(l_timestr);
      end if;
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
      <<shifts>>
      for i in 1..9999999 loop
         l_shift := get_node(l_xml, '/usgs-stream-rating/height-shifts['||i||']');
         exit when l_shift is null;
         if cwms_util.get_xml_nodes(l_shift, '/height-shifts/*').count = 0 then
            -- empty element tag
            exit;
         end if;
         l_temp := rating_t(
            p_rating_spec_id  => l_location_id
                                 ||cwms_rating.separator1||l_ind_param
                                 ||cwms_rating.separator2||l_ind_param||'-Shift'
                                 ||cwms_rating.separator1||l_template_version
                                 ||cwms_rating.separator1||l_rating_version,     
            p_native_units    => null,                                           
            p_effective_date  => null,                                           
            p_transition_date => null,                                           
            p_active_flag     => null,                                           
            p_formula         => null,                                           
            p_rating_info     => null,                                           
            p_description     => null,                                           
            p_office_id       => self.office_id);                                
         l_temp.create_date := null;
         ----------------------------------
         -- get the shift effective date --
         ----------------------------------
         l_timestr := get_text(l_shift, '/height-shifts/effective-date');
         if l_timestr is null then
            cwms_err.raise('ERROR', 'Required <effective-date> element not found on shift #'||i);
         end if;
         l_temp.effective_date := (self as rating_t).get_date(l_timestr);
         if l_temp.effective_date < self.effective_date then
            cwms_err.raise(
               'ERROR',
               'Shift #'
               ||i
               ||' effective date ('
               ||to_char(l_temp.effective_date, 'yyyy-mm-dd hh24:mi')
               ||') pre-dates rating effective date ('
               ||to_char(self.effective_date, 'yyyy-mm-dd hh24:mi')
               ||')');
         end if;
         -----------------------------------
         -- get the shift transition date --
         -----------------------------------
         l_timestr := get_text(l_shift, '/height-shifts/transition-start-date');
         if l_timestr is not null then
            l_temp.transition_date := (self as rating_t).get_date(l_timestr);
         end if;
         ----------------------------------
         -- get the shift create date --
         ----------------------------------
         l_timestr := get_text(l_shift, '/height-shifts/create-date');
         if l_timestr is not null then
            l_temp.create_date := (self as rating_t).get_date(l_timestr);
         end if;
         -------------------------------
         -- get the shift active flag --
         -------------------------------
         l_temp.active_flag :=
            case get_text(l_shift, '/height-shifts/active')
               when 'true'  then 'T'
               when '1'     then 'T'
               when 'false' then 'F'
               when '0'     then 'F'
               else               null
            end;
         if l_temp.active_flag is null then
            cwms_err.raise(
               'ERROR',
               'Invalid text for <active> element: '
               ||get_text(l_shift, '/height-shifts/active'));
         end if;
         ----------------------------
         -- get the shift units id --
         ----------------------------
         l_parts := cwms_util.split_text(self.native_units, cwms_rating.separator2);
         l_temp.native_units := l_parts(1) || cwms_rating.separator2 || l_parts(1);
         -------------------------------
         -- get the shift description --
         -------------------------------
         l_temp.description := get_text(l_shift, '/height-shifts/description');
         --------------------------
         -- for each shift point --
         --------------------------
         <<points>>
         for j in 1..9999999 loop
            l_point := get_node(l_shift, '/height-shifts/point['||j||']');
            exit when l_point is null;
            ------------------------------------------------------------
            -- create a new rating_value_t object for the shift point --
            ------------------------------------------------------------
            if l_temp.rating_info is null then
               l_temp.rating_info := rating_ind_parameter_t(
                  'F',                  -- constructed
                  rating_value_tab_t(), -- rating_values
                  null);                -- extension_values
            end if;
            l_temp.rating_info.rating_values.extend();
            l_temp.rating_info.rating_values(j) := rating_value_t();
            l_temp.rating_info.rating_values(j).ind_value := get_number(l_point, '/point/ind');
            l_temp.rating_info.rating_values(j).dep_value := get_number(l_point, '/point/dep');
            l_temp.rating_info.rating_values(j).note_id   := get_text(l_point, '/point/note');
         end loop points;
         if l_temp.rating_info is not null then
            l_temp.rating_info.constructed := 'T';
            begin
               l_temp.rating_info.validate_obj(1);
            exception
               when others then
                  cwms_msg.log_db_message(
                     'stream_rating_t.store',
                     cwms_msg.msg_level_normal,
                     'Rating shift '||i||' skipped due to '||sqlerrm);
                  continue shifts;
            end;
         end if;
         if self.shifts is null then
            self.shifts := rating_tab_t();
         end if;
         self.shifts.extend;
         self.shifts(self.shifts.count) := l_temp;
      end loop shifts;
      l_offsets := get_node(l_xml, '/usgs-stream-rating/height-offsets');
      for i in 1..1 loop
         if l_offsets is not null then
            if cwms_util.get_xml_nodes(l_offsets, '/height-offsets/*').count = 0 then
               -- empty element tag
               exit;
            end if;
            ------------------------------------------------------
            -- create a new rating_t object to hold the offsets --
            ------------------------------------------------------
            self.offsets := rating_t(
               p_rating_spec_id  => l_location_id
                                    ||cwms_rating.separator1||l_ind_param
                                    ||cwms_rating.separator2||l_ind_param||'-Offset'
                                    ||cwms_rating.separator1||l_template_version                         
                                    ||cwms_rating.separator1||l_rating_version,
               p_native_units    => null,                                
               p_effective_date  => self.effective_date,
               p_transition_date => null,
               p_active_flag     => self.active_flag,                    
               p_formula         => null,                                
               p_rating_info     => null,                                
               p_description     => 'Logarithmic interpolation offsets', 
               p_office_id       => self.office_id);                     
            self.offsets.create_date := self.create_date;
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
               if self.offsets.rating_info is null then
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
               if self.offsets.rating_info is not null then
                  self.offsets.rating_info.constructed := 'T';
               end if;
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
      end loop;
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
            if self.rating_info is null then
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
         l_extension_points := get_node(l_xml, '/usgs-stream-rating/extension-points');
         if l_extension_points is not null then
            ------------------------------
            -- for each extension point --
            ------------------------------
            for i in 1..9999999 loop
               l_point := get_node(l_extension_points, '/extension-points/point['||i||']');
               exit when l_point is null;
               if self.rating_info is null then
                  cwms_err.raise('ERROR', 'Cannot create rating with extension points and no rating points');
               end if;
               if self.rating_info.extension_values is null then
                  self.rating_info.extension_values := rating_value_tab_t();
               end if;
               self.rating_info.extension_values.extend();
               self.rating_info.extension_values(i) := rating_value_t();
               self.rating_info.extension_values(i).ind_value := get_number(l_point, '/point/ind');
               self.rating_info.extension_values(i).dep_value := get_number(l_point, '/point/dep');
               self.rating_info.extension_values(i).note_id   := get_text(l_point, '/point/note');
            end loop;
         end if;
         if self.rating_info is not null then
            self.rating_info.constructed := 'T';
            self.rating_info.validate_obj(1);
         end if;
      end if;
      self.current_units := 'N';
      self.current_time := 'D'; 
      if self.offsets is not null then
         self.offsets.current_units := self.current_units;
         self.offsets.current_time  := self.current_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).current_units := self.current_units;
            self.shifts(i).current_time  := self.current_time;
         end loop;
      end if;
      self.validate_obj;
      return;
   end;

   constructor function stream_rating_t(
      p_other in stream_rating_t)
   return self as result
   is
   begin
      init(p_other);   
      return;
   end;
          
   member procedure init(
      p_other in stream_rating_t)
   is 
   begin
      self.office_id       := p_other.office_id;
      self.rating_spec_id  := p_other.rating_spec_id;
      self.effective_date  := p_other.effective_date;
      self.transition_date := p_other.transition_date;
      self.create_date     := p_other.create_date;
      self.active_flag     := p_other.active_flag;
      self.formula         := p_other.formula;
      self.native_units    := p_other.native_units;
      self.description     := p_other.description;
      self.rating_info     := p_other.rating_info;
      self.current_units   := p_other.current_units;
      self.current_time    := p_other.current_time;
      self.offsets         := p_other.offsets;
      self.shifts          := p_other.shifts;                                 
   end;
         
   overriding member procedure init(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
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
      if self.offsets is not null then
         self.offsets.current_units := self.current_units;
         self.offsets.current_time  := self.current_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            self.shifts(i).current_units := self.current_units;
            self.shifts(i).current_time  := self.current_time;
         end loop;
      end if;
      self.validate_obj;
   end;

   overriding member procedure validate_obj(
      p_include_points in varchar2 default 'T')
   is
      l_parts         str_tab_t;
      l_ind_param     varchar2(256);
      l_dep_param     varchar2(256);
      l_parameters_id varchar2(256); 
      l_temp          rating_t;
      l_prev          rating_t;
   begin
      ------------------------
      -- validate as rating --
      ------------------------
      (self as rating_t).validate_obj(p_include_points);
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
               l_temp := treat(self.shifts(i) as rating_t);
               l_temp.validate_obj;
               if l_temp.office_id != self.office_id then
                  cwms_err.raise('ERROR', 'Shifts office does not match rating office');
               end if;
               l_parts := cwms_util.split_text(l_temp.rating_spec_id, cwms_rating.separator1);
               l_parameters_id := l_parts(2);
               if l_parameters_id != l_ind_param || cwms_rating.separator2 || l_ind_param || '-Shift' then
                  cwms_err.raise('ERROR', 'Invalid shift parameter id - should be '||l_ind_param||cwms_rating.separator2||l_ind_param||'-Shift');
               end if;
               if l_temp.effective_date < self.effective_date then
                  cwms_err.raise(
                     'ERROR',
                     'Shift '||i||' effective date ('
                     ||l_temp.effective_date
                     ||') is earlier than rating effective date ('
                     ||self.effective_date
                     ||')');
               end if;
               if l_temp.transition_date is not null then
                  if i = 1 then
                     if l_temp.transition_date < self.effective_date then
                        cwms_err.raise(
                           'ERROR',
                           'Shift 1 transition date ('
                           ||to_char(l_temp.transition_date, 'yyyy/mm/dd hh24:mi:ss')
                           ||') is earlier than rating effective date ('
                           ||to_char(self.effective_date, 'yyyy/mm/dd hh24:mi:ss')
                           ||')');
                     end if;
                  else
                     l_prev := treat(self.shifts(i-1) as rating_t);
                     if l_temp.transition_date < l_prev.effective_date then
                        cwms_err.raise(
                           'ERROR',
                           'Shift '|| i ||' transition date ('
                           ||to_char(l_temp.transition_date, 'yyyy/mm/dd hh24:mi:ss')
                           ||') is earlier than shift '|| (i-1) ||' effective date ('
                           ||to_char(l_prev.effective_date, 'yyyy/mm/dd hh24:mi:ss')
                           ||')');
                     end if;
                  end if;
               end if;
               if l_temp.create_date is not null then
                  if self.create_date is null or l_temp.create_date < self.create_date then
                     cwms_err.raise(
                        'ERROR',
                        'Shift '||i||' create date ('
                        ||to_char(l_temp.create_date, 'yyyy/mm/dd hh24:mi:ss')
                        ||') is earlier than rating create date ('
                        ||to_char(self.create_date, 'yyyy/mm/dd hh24:mi:ss')
                        ||')');
                  end if;
               end if;
               if l_temp.formula is not null then
                  cwms_err.raise('ERROR', 'Shifts cannot use a formula');
               end if;
               if l_temp.native_units is null then
                  cwms_err.raise('ERROR', 'Shifts must use same unit as rating stage or elevation unit');
               end if;
               l_parts := cwms_util.split_text(l_temp.native_units, cwms_rating.separator2);
               if l_parts.count != 2 or l_parts(1) != l_parts(2) then
                  cwms_err.raise('ERROR', 'Invalid native units for shifts');
               end if;
               if substr(self.native_units, 1, instr(self.native_units, cwms_rating.separator2) - 1) != l_parts(1) then
                  cwms_err.raise('ERROR', 'Shifts must use same unit as rating stage or elevation unit');
               end if;
               if l_temp.rating_info.extension_values is not null then
                  cwms_err.raise('ERROR', 'Shifts cannot contain extension values');
               end if;
               if l_temp.rating_info.rating_values is null then
                  cwms_err.raise('ERROR', 'Shifts must contain rating values if specified');
               end if;
               for j in 1..l_temp.rating_info.rating_values.count loop
                  if j > 1 then
                     if l_temp.rating_info.rating_values(j).ind_value <=
                        l_temp.rating_info.rating_values(j-1).ind_value
                     then
                        cwms_err.raise(
                           'ERROR',
                           'Shifts stages/elevations do not monotonically increase after value '
                           ||cwms_rounding.round_dt_f(l_temp.rating_info.rating_values(j-1).ind_value, '9999999999'));
                     end if;
                  end if;
                  if l_temp.rating_info.rating_values(j).dep_value is null or
                     l_temp.rating_info.rating_values(j).dep_rating_ind_param is not null
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
      l_temp rating_t;
   begin               
      (self as rating_t).convert_to_database_units;
      if self.offsets is not null then 
         self.offsets.convert_to_database_units;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            l_temp := treat(self.shifts(i) as rating_t);
            l_temp.convert_to_database_units;
            self.shifts(i) := l_temp;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_native_units
   is
      l_temp rating_t;
   begin
      (self as rating_t).convert_to_native_units;
      if self.offsets is not null then
         self.offsets.convert_to_native_units;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            l_temp := treat(self.shifts(i) as rating_t);
            l_temp.convert_to_native_units;
            self.shifts(i) := l_temp;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_database_time
   is             
      l_temp rating_t;
   begin
      (self as rating_t).convert_to_database_time;
      if self.offsets is not null then
         self.offsets.convert_to_database_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            l_temp := treat(self.shifts(i) as rating_t);
            l_temp.convert_to_database_time;
            self.shifts(i) := l_temp;
         end loop;
      end if;
   end;

   overriding member procedure convert_to_local_time
   is
      l_temp rating_t;
   begin
      (self as rating_t).convert_to_local_time;
      if self.offsets is not null then
         self.offsets.convert_to_local_time;
      end if;
      if self.shifts is not null then
         for i in 1..self.shifts.count loop
            l_temp := treat(self.shifts(i) as rating_t);
            l_temp.convert_to_local_time;
            self.shifts(i) := l_temp;
         end loop;
      end if;
   end;

   overriding member procedure store(
      p_fail_if_exists in varchar2)
   is
   begin
      store(p_fail_if_exists, 'F'); 
   end;
   
   member procedure store(
      p_fail_if_exists in varchar2,
      p_replace        in varchar2)
   is
      item_already_exists exception;
      pragma exception_init(item_already_exists, -20020);
      l_rating_code      number(10);
      l_ref_rating_code  number(10);
      l_template         rating_template_t;
      l_parts            str_tab_t;
      l_location_id      varchar2(57);
      l_ind_param        varchar2(16);
      l_template_version varchar2(32);
      l_spec_version     varchar2(23);
      l_spec             rating_spec_t;
      l_rating_spec      rating_spec_t;
      l_clone            stream_rating_t;
      l_temp             rating_t;
      l_existing_rating  stream_rating_t; 
      l_replace          boolean;
      l_new_base_rating  boolean;
      l_base_stored      boolean;
      
      function same_rating_values( 
         p_rv1 in rating_value_tab_t,
         p_rv2 in rating_value_tab_t)
         return boolean
      is
         l_same boolean := false;
      begin
         if (p_rv1 is null) = (p_rv2 is null) then
            if p_rv1 is not null then
               if p_rv1.count = p_rv2.count then
                  for i in 1..p_rv1.count loop
                     exit when cwms_rounding.round_dd_f(p_rv1(i).ind_value - p_rv2(i).ind_value, '9999999999') != 0D;
                     if p_rv1(i).dep_value is null then
                        exit when p_rv2(i).dep_value is not null;
                        exit when not same_rating_values(
                           treat(p_rv1(i).dep_rating_ind_param as rating_ind_parameter_t).rating_values,
                           treat(p_rv2(i).dep_rating_ind_param as rating_ind_parameter_t).rating_values);
                     else
                        exit when p_rv2(i).dep_value is null;
                        exit when cwms_rounding.round_dd_f(p_rv1(i).dep_value - p_rv2(i).dep_value, '9999999999') != 0D;
                     end if;
                     l_same := true;   
                  end loop;
               end if;
            end if;
         end if;
         return l_same;
      end same_rating_values;
   begin
      if self.current_units = 'N' or self.current_time = 'L' then
         l_clone := stream_rating_t(self);  
         if self.current_units = 'N' then
            l_clone.convert_to_database_units;
         end if;
         if self.current_time = 'L' then
            l_clone.convert_to_database_time;
         end if;
         l_clone.store(p_fail_if_exists, p_replace);
         return;
      end if;
      l_parts             := cwms_util.split_text(self.rating_spec_id, cwms_rating.separator1);
      l_location_id       := l_parts(1);
      l_template_version  := l_parts(3);
      l_spec_version      := l_parts(4);
      l_parts             := cwms_util.split_text(l_parts(2), cwms_rating.separator2);
      l_ind_param         := cwms_util.get_base_id(l_parts(1));
      l_rating_spec       := rating_spec_t(self.rating_spec_id, self.office_id);
      l_replace           := cwms_util.return_true_or_false(p_replace);
      ---------------------------------------------------------------------------
      -- try to store the base rating, returning the rating code for reference --
      ---------------------------------------------------------------------------
      begin  
         l_new_base_rating := false;
         l_base_stored := false;
         (self as rating_t).store(l_ref_rating_code, 'T');
         l_new_base_rating := true;
         l_base_stored := true;
      exception                
         when item_already_exists then
            if cwms_util.return_true_or_false(p_fail_if_exists) then 
               raise; 
            end if; 
            if not l_replace then
               ----------------------------------------
               -- see if the base rating is the same --
               ----------------------------------------
               select rating_code
                 into l_ref_rating_code
                 from at_rating
                where rating_spec_code = rating_spec_t.get_rating_spec_code(self.rating_spec_id, self.office_id)
                  and effective_date = self.effective_date;
               
               l_existing_rating := stream_rating_t(l_ref_rating_code);
               l_existing_rating.convert_to_database_units;
               l_existing_rating.convert_to_database_time;  
               l_new_base_rating := false;
               for i in 1..1 loop
                  exit when 
                     (l_existing_rating.offsets is null) != 
                     (self.offsets is null);
                  exit when not same_rating_values( 
                     l_existing_rating.rating_info.rating_values, 
                     self.rating_info.rating_values);
                  l_new_base_rating := true;
               end loop;
               l_base_stored := false;
            end if;
      end;   
      if l_replace or l_new_base_rating then
         -------------------------------------------------
         -- store the base rating if we haven't already --
         -------------------------------------------------
         if not l_base_stored then
            (self as rating_t).store(l_ref_rating_code, 'F');
         end if;
         ------------------------------------------------------------------------
         -- delete any existing shift or offset data before storing new values --
         ------------------------------------------------------------------------
         for rec1 in (select rating_code 
                        from at_rating 
                       where ref_rating_code = l_ref_rating_code
                     ) 
         loop
            for rec2 in (select rating_ind_param_code 
                           from at_rating_ind_parameter 
                          where rating_code = rec1.rating_code
                        )
            loop
               delete 
                 from at_rating_value 
                where rating_ind_param_code = rec2.rating_ind_param_code;
               delete 
                 from at_rating_extension_value 
                where rating_ind_param_code = rec2.rating_ind_param_code;
               delete
                 from at_rating_ind_parameter
                where rating_ind_param_code = rec2.rating_ind_param_code;
            end loop;
            delete 
              from at_rating 
             where rating_code = rec1.rating_code;
         end loop;
         -----------------------
         -- store the offsets --
         -----------------------
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
               'PREVIOUS',
               'NEAREST',
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
      end if;
      ----------------------
      -- store the shifts --
      ----------------------
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
            l_temp := treat(self.shifts(i) as rating_t);
            l_temp.store(l_rating_code, 'F');
            update at_rating
               set ref_rating_code = l_ref_rating_code
             where rating_code = l_rating_code;
         end loop;
      end if;
   end;

   overriding member function to_clob(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return clob
   is
      l_text  clob;
      l_clone stream_rating_t;
      l_tzone varchar2(28);
      l_temp  rating_t;
      l_parts str_tab_t;
      l_units varchar2(64);       
      
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
      if self is of (vdatum_stream_rating_t) then
         l_clone := vdatum_stream_rating_t(treat(self as vdatum_stream_rating_t));
      else 
         l_clone := stream_rating_t(self);
      end if;
      l_clone.convert_to_database_units;
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
      if p_units is not null and upper(trim(p_units)) != 'NATIVE' then
         l_parts := cwms_util.split_text(replace(cwms_util.split_text(l_clone.rating_spec_id, 2, '.'), ';', ','), ',');
         l_units := cwms_util.get_default_units(l_parts(1), upper(trim(p_units)))||';'||cwms_util.get_default_units(l_parts(2), upper(trim(p_units)));
         l_clone.native_units := l_units;
         l_parts := cwms_util.split_text(l_units, ';');
         l_units := l_parts(1)||';'||l_parts(1);
         if l_clone.offsets is not null then
            l_clone.offsets.native_units := l_units;
         end if;
         if l_clone.shifts is not null then
            for i in 1..l_clone.shifts.count loop
               l_clone.shifts(i).native_units := l_units;
            end loop;
         end if;
      end if;
      l_clone.convert_to_native_units;
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text,
         '<usgs-stream-rating office-id="'||l_clone.office_id||'">'
         ||'<rating-spec-id>'||l_clone.rating_spec_id||'</rating-spec-id>'
         ||'<units-id>'||l_clone.native_units||'</units-id>'
         ||'<effective-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_clone.effective_date, 'UTC', l_tzone), l_tzone)||'</effective-date>');
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
      cwms_util.append(l_text,
         '<active>'
         ||bool_text(cwms_util.is_true(l_clone.active_flag))
         ||'</active>');
      if l_clone.description is not null then
         cwms_util.append(l_text, '<description>'||l_clone.description||'</description>');
      end if;
      -------------------
      -- output shifts --
      -------------------
      if l_clone.shifts is not null then
         for i in 1..l_clone.shifts.count loop
            l_temp := treat(l_clone.shifts(i) as rating_t);
            cwms_util.append(l_text,
               '<height-shifts><effective-date>'
               ||cwms_util.get_xml_time(cwms_util.change_timezone(l_temp.effective_date, 'UTC', l_tzone), l_tzone)||'</effective-date>');
            if l_temp.transition_date is null then
               null; -- cwms_util.append(l_text, '<transition-start-date/>');
            else
               cwms_util.append(l_text, '<transition-start-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_temp.transition_date, 'UTC', l_tzone), l_tzone)||'</transition-start-date>');
            end if;
            if l_temp.create_date is null then
               cwms_util.append(l_text, '<create-date/>');
            else
               cwms_util.append(l_text, '<create-date>'||cwms_util.get_xml_time(cwms_util.change_timezone(l_temp.create_date, 'UTC', l_tzone), l_tzone)||'</create-date>');
            end if;
            cwms_util.append(l_text,
               '<active>'
               ||bool_text(cwms_util.is_true(l_temp.active_flag))
               ||'</active>');
            if l_temp.description is not null then
               cwms_util.append(l_text, '<description>'||l_temp.description||'</description>');
            end if;
            for j in 1..l_temp.rating_info.rating_values.count loop
               cwms_util.append(l_text,
                  '<point><ind>'
                  ||cwms_rounding.round_dt_f(l_temp.rating_info.rating_values(j).ind_value, '9999999999')
                  ||'</ind><dep>'
                  ||cwms_rounding.round_dt_f(l_temp.rating_info.rating_values(j).dep_value, '9999999999')
                  ||'</dep>');
               if l_temp.rating_info.rating_values(j).note_id is not null then
                  cwms_util.append(l_text,
                     '<note>'
                     ||l_temp.rating_info.rating_values(j).note_id
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
      if l_clone.offsets is not null then
         cwms_util.append(l_text, '<height-offsets>');
         for i in 1..l_clone.offsets.rating_info.rating_values.count loop
            cwms_util.append(l_text,
               '<point><ind>'
               ||cwms_rounding.round_dt_f(l_clone.offsets.rating_info.rating_values(i).ind_value, '9999999999')
               ||'</ind><dep>'
               ||cwms_rounding.round_dt_f(l_clone.offsets.rating_info.rating_values(i).dep_value, '9999999999')
               ||'</dep>');
            if l_clone.offsets.rating_info.rating_values(i).note_id is not null then
               cwms_util.append(l_text,
                  '<note>'
                  ||l_clone.offsets.rating_info.rating_values(i).note_id
                  ||'</note>');
            end if;
            cwms_util.append(l_text, '</point>');
            end loop;
         cwms_util.append(l_text, '</height-offsets>');
      end if;
      ---------------------------------
      -- rating points and extension --
      ---------------------------------
      if l_clone.rating_info is null then
         cwms_util.append(l_text, '<rating-points/>');
      else
         -------------------
         -- rating points --
         -------------------
         cwms_util.append(l_text, '<rating-points>');
         for i in 1..l_clone.rating_info.rating_values.count loop
            cwms_util.append(l_text,
               '<point><ind>'
               ||cwms_rounding.round_dt_f(l_clone.rating_info.rating_values(i).ind_value, '9999999999')
               ||'</ind><dep>'
               ||cwms_rounding.round_dt_f(l_clone.rating_info.rating_values(i).dep_value, '9999999999')
               ||'</dep>');
            if l_clone.rating_info.rating_values(i).note_id is not null then
               cwms_util.append(l_text,
                  '<note>'
                  ||l_clone.rating_info.rating_values(i).note_id
                  ||'</note>');
            end if;
            cwms_util.append(l_text, '</point>');
         end loop;
         cwms_util.append(l_text, '</rating-points>');
         if l_clone.rating_info.extension_values is not null then
            cwms_util.append(l_text, '<extension-points>');
            for i in 1..l_clone.rating_info.extension_values.count loop
               cwms_util.append(l_text,
                  '<point><ind>'
                  ||cwms_rounding.round_dt_f(l_clone.rating_info.extension_values(i).ind_value, '9999999999')
                  ||'</ind><dep>'
                  ||cwms_rounding.round_dt_f(l_clone.rating_info.extension_values(i).dep_value, '9999999999')
                  ||'</dep>');
               if l_clone.rating_info.extension_values(i).note_id is not null then
                  cwms_util.append(l_text,
                     '<note>'
                     ||l_clone.rating_info.extension_values(i).note_id
                     ||'</note>');
               end if;
               cwms_util.append(l_text, '</point>');
            end loop;
            cwms_util.append(l_text, '</extension-points>');
         end if;
      end if;
      cwms_util.append(l_text, '</usgs-stream-rating>');
      dbms_lob.close(l_text);
      return l_text;
   end;

   overriding member function to_xml(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return xmltype
   is
   begin
      return xmltype(self.to_clob(p_timezone, p_units, p_vert_datum));
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
            l_clone := stream_rating_t(self);
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
      l_date_shifts             integer_tab_t;
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
      l_hi_value                number;
      l_lo_value                number;
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
      l_rounding_spec           varchar2(10);
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
            l_date_offsets := double_tab_t(effective_date - c_base_date);
            l_date_shifts  := integer_tab_t(0);
            if shifts(1).effective_date = effective_date then
               l_date_offsets(1) := l_date_offsets(1) - 1 / 1440;
            end if;
            for i in 1..shifts.count loop
               if shifts(i).transition_date is not null
                  and shifts(i).transition_date between case i when 1 then effective_date else shifts(i-1).effective_date end and shifts(i).effective_date
               then
                  l_date_offsets.extend;
                  l_date_shifts.extend;
                  l_date_offsets(l_date_offsets.count) := shifts(i).transition_date - c_base_date;
                  l_date_shifts(l_date_shifts.count) := i-1;
               end if;
               l_date_offsets.extend;
               l_date_shifts.extend;
               l_date_offsets(l_date_offsets.count) := shifts(i).effective_date - c_base_date;
               l_date_shifts(l_date_shifts.count) := i;
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
            while i <= rating_info.extension_values.count and
                  rating_info.extension_values(i).ind_value < rating_info.rating_values(1).ind_value
            loop
               l_heights.extend;
               l_flows.extend;
               k := k + 1;
               l_heights(k) := rating_info.extension_values(i).ind_value;
               l_flows(k) := rating_info.extension_values(i).dep_value;
               i := 1 + i;
            end loop;
         end if;
         ----------------------------
         -- next the rating values --
         ----------------------------
         while j <= rating_info.rating_values.count loop
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
            while i <= rating_info.extension_values.count loop
               if rating_info.extension_values(i).ind_value >
                  rating_info.rating_values(rating_info.rating_values.count).ind_value
               then
                  l_heights.extend;
                  l_flows.extend;
                  k := k + 1;
                  l_heights(k) := rating_info.extension_values(i).ind_value;
                  l_flows(k) := rating_info.extension_values(i).dep_value;
               end if;
               i := i + 1;
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
               if l_rounding_spec is null then
                  select rir.rounding_spec
                    into l_rounding_spec  
                    from at_rating_ind_rounding rir
                   where rir.rating_spec_code = 
                         (select r.rating_spec_code
                            from at_rating r
                           where r.rating_code 
                                 = rating_t.get_rating_code(
                                      p_rating_spec_id => self.rating_spec_id,
                                      p_effective_date => self.effective_date,
                                      p_match_date     => 'T',
                                      p_time_zone      => case self.current_time
                                                          when 'D' then 'UTC'
                                                          else cwms_loc.get_local_timezone(
                                                             cwms_util.split_text(self.rating_spec_id, 1, '.'), 
                                                             self.office_id)
                                                          end,
                                      p_office_id      => self.office_id)
                         )   
                     and rir.parameter_position = 1; 
               end if;   
               l_height := cwms_rounding.round_nn_f(l_height, l_rounding_spec);
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
                  if l_date_shifts(l_hi_index) = 0 then
                     l_hi_value := 0; -- no shift on base curve
                  else
                     l_hi_value := treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rate(l_height);
                  end if;
               end if;
               if l_ratio != 1. then
                  if l_hi_index = 1 then
                     l_lo_value := 0.;
                  else
                     if l_date_shifts(l_hi_index-1) = 0 then
                        l_lo_value := 0; -- no shift on base curve
                     else
                        l_lo_value := treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rate(l_height);
                     end if;
                  end if;
               end if;
               l_shift := case l_ratio
                          when 0D then l_lo_value
                          when 1D then l_hi_value
                          else l_lo_value + l_ratio * (l_hi_value - l_lo_value) 
                          end;
               if l_shift != 0D then                         
                  l_height := l_height + cwms_rounding.round_nn_f(l_shift, l_rounding_spec);
               end if;
            end if;
            -----------------------------------
            -- find the interpolation values --
            -----------------------------------
            l_hi_index := cwms_lookup.find_high_index(
               l_height,
               l_heights,
               l_heights_properties);
            case l_height
            when l_heights(l_hi_index) then
               l_results(i).value := l_flows(l_hi_index);
            when l_heights(l_hi_index-1) then
               l_results(i).value := l_flows(l_hi_index-1);
            else
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
            end case;   
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
            l_clone := stream_rating_t(self);
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
      l_date_shifts             integer_tab_t;
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
            l_date_offsets := double_tab_t(effective_date - c_base_date);
            l_date_shifts  := integer_tab_t(0);
            if shifts(1).effective_date = effective_date then
               l_date_offsets(1) := l_date_offsets(1) - 1 / 1440;
            end if;
            for i in 1..shifts.count loop
               if shifts(i).transition_date is not null
                  and shifts(i).transition_date between case i when 1 then effective_date else shifts(i-1).effective_date end and shifts(i).effective_date
               then
                  l_date_offsets.extend;
                  l_date_offsets(l_date_offsets.count) := shifts(i).transition_date - c_base_date;
                  l_date_shifts.extend;
                  l_date_shifts(l_date_shifts.count) := i-1;
               end if;
               l_date_offsets.extend;
               l_date_offsets(l_date_offsets.count) := shifts(i).effective_date - c_base_date;
               l_date_shifts.extend;
               l_date_shifts(l_date_shifts.count) := i;
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
                     if l_date_shifts(l_hi_index) = 0 then
                        l_hi_value := 0.; -- zero shift on base curve
                     else
                        l_heights.delete;
                        l_heights.extend(treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rating_info.rating_values.count);
                        l_shifts := double_tab_t();
                        l_shifts.extend(treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rating_info.rating_values.count);
                        for j in 1..treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rating_info.rating_values.count loop
                           l_heights(j) := treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rating_info.rating_values(j).ind_value;
                           l_shifts(j) := treat(shifts(l_date_shifts(l_hi_index)) as rating_t).rating_info.rating_values(j).dep_value;
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
                  end if;
                  if l_ratio != 1. then
                     if l_date_shifts(l_hi_index) = 0 then
                        l_lo_value := 0.; -- zero shift on base curve
                     else
                        l_heights.delete;
                        l_heights.extend(treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rating_info.rating_values.count);
                        l_shifts := double_tab_t();
                        l_shifts.extend(treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rating_info.rating_values.count);
                        for j in 1..treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rating_info.rating_values.count loop
                           l_heights(j) := treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rating_info.rating_values(j).ind_value;
                           l_shifts(j) := treat(shifts(l_date_shifts(l_hi_index-1)) as rating_t).rating_info.rating_values(j).dep_value;
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
                  l_shift := cwms_rounding.round_dd_f(l_shift, '2223456782');
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

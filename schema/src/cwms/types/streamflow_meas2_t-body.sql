create or replace type body streamflow_meas2_t
as
   constructor function streamflow_meas2_t (
      p_rdb_line  in varchar2,
      p_office_id in varchar2 default null)
      return self as result
   is
      l_office_id  varchar2(16);
      l_parts      str_tab_t;
      l_timestamp  timestamp;
      l_utc_offset interval day (0) to second (3);
      l_field_count pls_integer;
   begin
      for i in 1..1 loop
         if p_rdb_line is null or substr(p_rdb_line, 1, 1) = '#' then
            exit;
         end if;
         l_parts := cwms_util.split_text(p_rdb_line, chr(9));
         l_field_count := l_parts.count;
         if l_field_count not in (15, 18, 35) then
            cwms_err.raise(
               'ERROR',
               'Expected 15, 18, or 35 fields in input, got '||l_parts.count||chr(10)||p_rdb_line);
         end if;
         if upper(l_parts(1)) != l_parts(1) or upper(l_parts(6)) not in ('Y', 'YES') then
            exit;
         end if;
         l_office_id         := cwms_util.get_db_office_id(p_office_id);
         self.location       := location_ref_t(cwms_loc.get_location_id(l_parts(2), l_office_id), l_office_id);
         self.meas_number    := l_parts(3);
         if length(l_parts(4)) = 10 then
            -- date only
            self.date_time   := to_date(l_parts(4), 'yyyy-mm-dd');
            self.time_zone   := null;
         else
            -- date, time, and tz
            l_timestamp := to_timestamp(l_parts(4), 'yyyy-mm-dd hh24:mi:ss');
            select tz_utc_offset
              into l_utc_offset
              from cwms_usgs_time_zone
             where tz_id = l_parts(5);
         self.date_time      := cast((l_timestamp - l_utc_offset) as date);
         self.time_zone      := 'UTC';
         end if;
         self.used           := case when substr(l_parts(6), 1, 1) = 'Y' then 'T' else 'F' end;
         self.party          := l_parts(7);
         self.agency_id      := l_parts(8);
         self.gage_height    := to_binary_double(l_parts(9));
         self.flow           := to_binary_double(l_parts(10));
         self.cur_rating_num := case when l_field_count = 15 then null else l_parts(11) end;
         self.shift_used     := case when l_field_count = 15 then null else to_binary_double(l_parts(12)) end;
         self.pct_diff       := case when l_field_count = 15 then null else to_binary_double(l_parts(13)) end;
         self.quality        := upper(substr(case when l_field_count = 15 then l_parts(11) else l_parts(14) end, 1, 1));
         self.delta_height   := to_binary_double(case when l_field_count = 15 then l_parts(12) else l_parts(15) end);
         self.delta_time     := to_binary_double(case when l_field_count = 15 then l_parts(13) else l_parts(16) end);
         self.ctrl_cond_id   := case when l_field_count = 15 then l_parts(14) else l_parts(17) end;
         self.flow_adj_id    := case when l_field_count = 15 then l_parts(15) else l_parts(18) end;
         self.height_unit    := 'ft';
         self.flow_unit      := 'cfs';
         self.velocity_unit  := 'fps';
         self.area_unit      := 'ft2';
         self.temp_unit      := 'F';
         self.time_zone      := 'UTC';

         if upper(self.ctrl_cond_id) = 'UNSPECIFED' then self.ctrl_cond_id := 'Unspecified'; end if;
         if upper(self.flow_adj_id)  = 'UNKN'       then self.flow_adj_id  := 'UNSP';        end if;

         select count(*) into l_field_count from cwms_usgs_meas_qual where qual_id = self.quality;
         if l_field_count = 0 then self.quality := null; end if;

         select count(*) into l_field_count from cwms_usgs_rating_ctrl_cond where ctrl_cond_id = self.ctrl_cond_id;
         if l_field_count = 0 then self.ctrl_cond_id := null; end if;

         select count(*) into l_field_count from cwms_usgs_flow_adj where adj_id = self.flow_adj_id;
         if l_field_count = 0 then self.ctrl_cond_id := null; end if;

      end loop;
      return;
   end streamflow_meas2_t;

   constructor function streamflow_meas2_t (
      p_xml in xmltype)
      return self as result
   is
      function get_text(p_path in varchar2, p_required in boolean default false) return varchar2
      is
         l_text varchar2(32767);
      begin
         l_text := cwms_util.get_xml_text(p_xml, p_path);
         if l_text is null and p_required then
            cwms_err.raise('ERROR', 'Required element or attribute is null or not found: '||p_path);
         end if;
         return l_text;
      end get_text;
   begin
      if p_xml.getrootelement != 'measurement' then
         cwms_err.raise(
            'ERROR',
            'Expected <measurement>, got <'||p_xml.getrootelement||'>');
      end if;
      -- Extract top-level attributes and elements
      self.location       := location_ref_t(get_text('/*/location', true), get_text('/*/@office-id', true));
      self.used           := case get_text('/*/@used', true) when 'true' then 'T' else 'F' end;
      self.height_unit    := get_text('/*/@height-unit', self.used='T');
      self.flow_unit      := get_text('/*/@flow-unit', self.used='T');
      self.meas_number    := get_text('/*/number', true);
      self.time_zone      := nvl(cwms_loc.get_local_timezone(p_location_code => self.location.get_location_code), 'UTC');
      self.date_time      := cwms_util.change_timezone(cast(cwms_util.to_timestamp(get_text('/*/date', true)) as date), 'UTC', self.time_zone);
      self.agency_id      := get_text('/*/agency');
      self.party          := get_text('/*/party');
      self.wm_comments    := get_text('/*/wm-comments');

      -- Extract nested <stream-flow-measurement> elements
      self.gage_height    := to_binary_double(get_text('/*/stream-flow-measurement/gage-height', self.used='T'));
      self.flow           := to_binary_double(get_text('/*/stream-flow-measurement/flow', self.used='T'));
      self.quality        := substr(upper(trim(get_text('/*/stream-flow-measurement/quality'))),1,1);

      -- Extract nested <usgs-measurement> elements
      self.cur_rating_num := get_text('/*/usgs-measurement/current-rating', false);
      self.ctrl_cond_id   := get_text('/*/usgs-measurement/control-condition', false);
      self.shift_used     := to_binary_double(get_text('/*/usgs-measurement/shift-used', false));
      self.pct_diff       := to_binary_double(get_text('/*/usgs-measurement/percent-difference', false));
      self.flow_adj_id    := get_text('/*/usgs-measurement/flow-adjustment', false);
      self.delta_height   := to_binary_double(get_text('/*/usgs-measurement/delta-height', false));
      self.delta_time     := to_binary_double(get_text('/*/usgs-measurement/delta-time', false));
      self.remarks        := get_text('/*/usgs-measurement/remarks', false);
      self.air_temp       := to_binary_double(get_text('/*/usgs-measurement/air-temp', false));
      self.water_temp     := to_binary_double(get_text('/*/usgs-measurement/water-temp', false));
      self.temp_unit      := get_text('/*/@temp-unit', self.used='T' and (self.air_temp is not null or self.water_temp is not null));

      self.supp_streamflow_meas := supp_streamflow_meas_t(
          p_xml.extract('/measurement/supplemental-stream-flow-measurement'));
      self.area_unit  := get_text('/*/@area-unit', self.used='T' and self.supp_streamflow_meas is not null and (
            self.supp_streamflow_meas.effective_flow_area is not null or
            self.supp_streamflow_meas.cross_sectional_area is not null or
            self.supp_streamflow_meas.main_channel_area is not null or
            self.supp_streamflow_meas.overbank_area is not null));
      self.velocity_unit := get_text('/*/@velocity-unit', self.used='T' and self.supp_streamflow_meas is not null and (
            self.supp_streamflow_meas.avg_velocity is not null or
            self.supp_streamflow_meas.surface_velocity is not null or
            self.supp_streamflow_meas.max_velocity is not null));
      return;
   end streamflow_meas2_t;

   constructor function streamflow_meas2_t (
      p_location    in location_ref_t,
      p_date_time   in date,
      p_unit_system in varchar2 default 'EN',
      p_time_zone   in varchar2 default null)
      return self as result
   is
      l_rowid urowid;
      l_time_zone varchar2(28);
   begin
      l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location.get_location_code));
      select rowid
        into l_rowid
        from at_streamflow_meas
       where location_code = p_location.get_location_code
         and date_time = cwms_util.change_timezone(p_date_time, l_time_zone, 'UTC');

      self := new streamflow_meas2_t(l_rowid);
      return;
   end streamflow_meas2_t;

   constructor function streamflow_meas2_t (
      p_location    in location_ref_t,
      p_meas_number in varchar2,
      p_unit_system in varchar2 default 'EN')
      return self as result
   is
      l_rowid urowid;
   begin
      select rowid
        into l_rowid
        from at_streamflow_meas
       where location_code = p_location.get_location_code
         and meas_number = p_meas_number;

      self := new streamflow_meas2_t(l_rowid);
      return;
   end streamflow_meas2_t;

-- This is building from the db which is stored in SI
   constructor function streamflow_meas2_t (
      p_rowid       in urowid,
      p_unit_system in varchar2 default 'EN')
      return self as result
   is
      l_rec at_streamflow_meas%rowtype;
   begin
      select *
        into l_rec
        from at_streamflow_meas
       where rowid = p_rowid;

      self.location        := location_ref_t(l_rec.location_code);
      self.time_zone       := cwms_loc.get_local_timezone(p_location_code => l_rec.location_code);
        -- these are the units we are going to convert to
      self.height_unit     := cwms_util.get_default_units('Stage', p_unit_system);
      self.flow_unit       := cwms_util.get_default_units('Flow', p_unit_system);
      self.temp_unit       := cwms_util.get_default_units('Temp', p_unit_system);
      if upper(trim(p_unit_system)) = 'EN' then
        self.velocity_unit := 'fps';
      else
        self.velocity_unit := 'mps';
      end if;
      self.area_unit       := cwms_util.get_default_units('Area', p_unit_system);
      self.meas_number     := l_rec.meas_number;
      self.date_time       := cwms_util.change_timezone(l_rec.date_time, 'UTC', self.time_zone);
      self.used            := l_rec.used;
      self.agency_id       := cwms_entity.get_entity_id(l_rec.agency_code);
      self.party           := l_rec.party;
      self.gage_height     := cwms_util.convert_units(l_rec.gage_height, 'm', self.height_unit);
      self.flow            := cwms_util.convert_units(l_rec.flow, 'cms', self.flow_unit);
      self.cur_rating_num  := l_rec.cur_rating_num;
      self.shift_used      := cwms_util.convert_units(l_rec.shift_used, 'm', self.height_unit);
      self.pct_diff        := l_rec.pct_diff;
      self.quality         := l_rec.quality;
      self.delta_height    := cwms_util.convert_units(l_rec.delta_height, 'm', self.height_unit);
      self.delta_time      := l_rec.delta_time;
      self.ctrl_cond_id    := l_rec.ctrl_cond_id;
      self.flow_adj_id     := l_rec.flow_adj_id;
      self.remarks         := l_rec.remarks;
      self.air_temp        := cwms_util.convert_units(l_rec.air_temp, 'C', self.temp_unit);
      self.water_temp      := cwms_util.convert_units(l_rec.water_temp, 'C', self.temp_unit);
      self.wm_comments     := l_rec.wm_comments;
      self.supp_streamflow_meas := supp_streamflow_meas_t(
        xmltype(supp_streamflow_params_to_xml(
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.channel_flow, 'cms', self.flow_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.overbank_flow, 'cms', self.flow_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.overbank_max_depth, 'm', self.height_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.channel_max_depth, 'm', self.height_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.avg_velocity, 'mps', self.velocity_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.surface_velocity, 'mps', self.velocity_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.max_velocity, 'mps', self.velocity_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.effective_flow_area, 'm2', self.area_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.cross_sectional_area, 'm2', self.area_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.mean_gage, 'm', self.height_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.top_width, 'm', self.height_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.main_channel_area, 'm2', self.area_unit),
            cwms_util.convert_units(l_rec.supplemental_streamflow_meas.overbank_area, 'm2', self.area_unit)
        ))
      );

      return;
   end streamflow_meas2_t;

   member procedure set_height_unit(
      p_height_unit in varchar2)
   is
   begin
      if upper(p_height_unit) in ('EN', 'SI') then
         self.set_height_unit(cwms_util.get_default_units('Stage', upper(p_height_unit)));
      else
         self.gage_height  := cwms_util.convert_units(self.gage_height,  self.height_unit, p_height_unit);
         self.shift_used   := cwms_util.convert_units(self.shift_used,   self.height_unit, p_height_unit);
         self.delta_height := cwms_util.convert_units(self.delta_height, self.height_unit, p_height_unit);
         self.supp_streamflow_meas.channel_max_depth  := cwms_util.convert_units(self.supp_streamflow_meas.channel_max_depth, self.height_unit, p_height_unit);
         self.supp_streamflow_meas.overbank_max_depth := cwms_util.convert_units(self.supp_streamflow_meas.overbank_max_depth, self.height_unit, p_height_unit);
         self.supp_streamflow_meas.mean_gage          := cwms_util.convert_units(self.supp_streamflow_meas.mean_gage, self.height_unit, p_height_unit);
         self.supp_streamflow_meas.top_width          := cwms_util.convert_units(self.supp_streamflow_meas.top_width, self.height_unit, p_height_unit);
         self.height_unit  := p_height_unit;
      end if;
   end set_height_unit;

   member procedure set_flow_unit(
      p_flow_unit in varchar2)
   is
   begin
      if upper(p_flow_unit) in ('EN', 'SI') then
         self.set_flow_unit(cwms_util.get_default_units('Flow', upper(p_flow_unit)));
      else
         self.flow      := cwms_util.convert_units(self.flow, self.flow_unit, p_flow_unit);
         self.supp_streamflow_meas.channel_flow := cwms_util.convert_units(self.supp_streamflow_meas.channel_flow, self.flow_unit, p_flow_unit);
         self.supp_streamflow_meas.overbank_flow := cwms_util.convert_units(self.supp_streamflow_meas.overbank_flow, self.flow_unit, p_flow_unit);
         self.flow_unit := p_flow_unit;
      end if;
   end set_flow_unit;

   member procedure set_time_zone(
      p_time_zone in varchar2 default null)
   is
   begin
      self.date_time := cwms_util.change_timezone(self.date_time, self.time_zone, p_time_zone);
      self.time_zone := p_time_zone;
   end set_time_zone;

   member procedure store(
      p_fail_if_exists varchar2)
   is
      l_rec            at_streamflow_meas%rowtype;
      l_exists         boolean;
      l_error_message  varchar2(4000);

      function make_meas_number(
         p_date in date)
         return varchar2
      is
         l_date timestamp;
         l_yr   integer;
         l_hr   integer;
         l_mi   integer;
         l_doy  integer;
         l_2min integer;
         l_text varchar2(10);
      begin
         l_date := cast(p_date as timestamp);
         l_yr   := extract(year   from l_date);
         l_hr   := extract(hour   from l_date);
         l_mi   := extract(minute from l_date);
         l_doy  := trunc(l_date, 'ddd') - trunc(l_date, 'yyyy') + 1;
         l_2min := (60 * l_hr + l_mi) / 2;
         l_text := l_yr||trim(to_char(l_doy, '009'))||trim(to_char(l_2min, '009'));
         return trim(to_char(to_number(l_text), 'xxxxxxxx'));
      end make_meas_number;

      function get_entity_code(
         p_agency_id in varchar2)
         return integer
      is
         l_agency_code integer;
      begin
            l_agency_code := cwms_entity.get_entity_code(p_agency_id, self.location.office_id);
         return l_agency_code;
      end get_entity_code;
   begin
      l_rec.location_code := self.location.get_location_code;
      l_rec.date_time     := cwms_util.change_timezone(self.date_time, nvl(self.time_zone, cwms_loc.get_local_timezone(self.location.get_location_code)), 'UTC');
      l_rec.meas_number   := case self.meas_number is null
                             when false then self.meas_number
                             else make_meas_number(l_rec.date_time)
                             end;
      begin
         select *
           into l_rec
           from at_streamflow_meas
          where location_code = l_rec.location_code
            and meas_number = l_rec.meas_number;
         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;
      if l_exists and cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'CWMS streamflow measurement',
            self.location.office_id||'/'||self.location.get_location_id||' measurement number '||l_rec.meas_number);
      end if;
      l_rec.date_time      := cwms_util.change_timezone(self.date_time, nvl(self.time_zone, 'UTC'), 'UTC');
      l_rec.used           := self.used;
      l_rec.party          := self.party;
      l_rec.agency_code    := get_entity_code(self.agency_id);
      l_rec.gage_height    := cwms_util.convert_units(self.gage_height, self.height_unit, 'm');
      l_rec.flow           := cwms_util.convert_units(self.flow, self.flow_unit, 'cms');
      l_rec.cur_rating_num := self.cur_rating_num;
      l_rec.shift_used     := cwms_util.convert_units(self.shift_used, self.height_unit, 'm');
      l_rec.pct_diff       := self.pct_diff;
      l_rec.quality        := self.quality;
      l_rec.delta_height   := cwms_util.convert_units(self.delta_height, self.height_unit, 'm');
      l_rec.delta_time     := self.delta_time;
      l_rec.ctrl_cond_id   := self.ctrl_cond_id;
      l_rec.flow_adj_id    := self.flow_adj_id;
      l_rec.remarks        := self.remarks;
      l_rec.air_temp       := nvl(cwms_util.convert_units(self.air_temp, self.temp_unit, 'C'), l_rec.air_temp);
      l_rec.water_temp     := nvl(cwms_util.convert_units(self.water_temp, self.temp_unit, 'C'), l_rec.water_temp);
      l_rec.wm_comments    := nvl(self.wm_comments, l_rec.wm_comments);
      l_rec.supplemental_streamflow_meas := supp_streamflow_meas_t(
        xmltype(supp_streamflow_params_to_xml(
            p_channel_flow           => cwms_util.convert_units(self.supp_streamflow_meas.channel_flow, self.flow_unit, 'cms'),
            p_overbank_flow          => cwms_util.convert_units(self.supp_streamflow_meas.overbank_flow, self.flow_unit, 'cms'),
            p_overbank_max_depth     => cwms_util.convert_units(self.supp_streamflow_meas.overbank_max_depth, self.height_unit, 'm'),
            p_channel_max_depth      => cwms_util.convert_units(self.supp_streamflow_meas.channel_max_depth, self.height_unit, 'm'),
            p_avg_velocity           => cwms_util.convert_units(self.supp_streamflow_meas.avg_velocity, self.velocity_unit, 'mps'),
            p_surface_velocity       => cwms_util.convert_units(self.supp_streamflow_meas.surface_velocity, self.velocity_unit, 'mps'),
            p_max_velocity           => cwms_util.convert_units(self.supp_streamflow_meas.max_velocity, self.velocity_unit, 'mps'),
            p_effective_flow_area    => cwms_util.convert_units(self.supp_streamflow_meas.effective_flow_area, self.area_unit, 'm2'),
            p_cross_sectional_area  => cwms_util.convert_units(self.supp_streamflow_meas.cross_sectional_area, self.area_unit, 'm2'),
            p_mean_gage              => cwms_util.convert_units(self.supp_streamflow_meas.mean_gage, self.height_unit, 'm'),
            p_top_width              => cwms_util.convert_units(self.supp_streamflow_meas.top_width, self.height_unit, 'm'),
            p_main_channel_area      => cwms_util.convert_units(self.supp_streamflow_meas.main_channel_area, self.area_unit, 'm2'),
            p_overbank_area          => cwms_util.convert_units(self.supp_streamflow_meas.overbank_area, self.area_unit, 'm2')
        ))
    );

      begin
      if l_exists then
         update at_streamflow_meas
            set row = l_rec
          where location_code = l_rec.location_code
            and meas_number = l_rec.meas_number;
      else
         insert
           into at_streamflow_meas
         values l_rec;
      end if;
      exception
         when others then
            l_error_message := 'ERROR Storing Stream Measurement: '||sqlerrm
            ||chr(10)||chr(9)||'location       = '||self.location.get_office_id||'/'||self.location.get_location_id
            ||chr(10)||chr(9)||'meas_number    = '||self.meas_number
            ||chr(10)||chr(9)||'date_time      = '||to_char(self.date_time, 'yyyy-mm-dd hh24:mi')
            ||chr(10)||chr(9)||'used           = '||self.used
            ||chr(10)||chr(9)||'party          = '||self.party
            ||chr(10)||chr(9)||'agency_id      = '||self.agency_id
            ||chr(10)||chr(9)||'gage_height    = '||to_number(self.gage_height)
            ||chr(10)||chr(9)||'flow           = '||to_number(self.flow)
            ||chr(10)||chr(9)||'cur_rating_num = '||self.cur_rating_num
            ||chr(10)||chr(9)||'shift_used     = '||to_number(self.shift_used)
            ||chr(10)||chr(9)||'pct_diff       = '||to_number(self.pct_diff)
            ||chr(10)||chr(9)||'quality        = '||self.quality
            ||chr(10)||chr(9)||'delta_height   = '||to_number(self.delta_height)
            ||chr(10)||chr(9)||'delta_time     = '||to_number(self.delta_time)
            ||chr(10)||chr(9)||'ctrl_cond_id   = '||self.ctrl_cond_id
            ||chr(10)||chr(9)||'flow_adj_id    = '||self.flow_adj_id
            ||chr(10)||chr(9)||'remarks        = '||self.remarks
            ||chr(10)||chr(9)||'time_zone      = '||self.time_zone
            ||chr(10)||chr(9)||'height_unit    = '||self.height_unit
            ||chr(10)||chr(9)||'flow_unit      = '||self.flow_unit
            ||chr(10)||chr(9)||'temp_unit      = '||self.temp_unit
            ||chr(10)||chr(9)||'velocity_unit  = '||self.velocity_unit
            ||chr(10)||chr(9)||'area_unit      = '||self.area_unit
            ||chr(10)||chr(9)||'air_temp       = '||to_number(self.air_temp)
            ||chr(10)||chr(9)||'water_temp     = '||to_number(self.water_temp)
            ||chr(10)||chr(9)||'wm_comments    = '||self.wm_comments
            ||chr(10)||chr(9)||self.supp_streamflow_meas.get_error_message;
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, l_error_message);
         raise;
      end;
   end store;

   member function to_xml
      return xmltype
   is
   Begin
      return xmltype(self.to_string1);
   end to_xml;

   member function to_string1
      return varchar2
   is
      l_text    varchar2(32767);
      l_quality varchar2(16);

      function make_elem(p_tag in varchar2, p_data in varchar2) return varchar2
      is
         l_elem varchar2(32767);
      begin
         if p_data is null then
            l_elem := '<'||p_tag||'/>';
         else
            l_elem := '<'||p_tag||'>'||p_data||'</'||p_tag||'>';
         end if;
         return l_elem;
      end;
   begin
      if self.quality is not null then
         select qual_name
           into l_quality
           from cwms_usgs_meas_qual
          where qual_id = self.quality;
      end if;
      l_text := '<measurement'
          ||' office-id="'||self.location.office_id||'"'
          ||' height-unit="'||self.height_unit||'"'
          ||' flow-unit="'||self.flow_unit||'"'
          ||case self.temp_unit is not null when true then ' temp-unit="'||self.temp_unit||'"' else null end
          ||case self.area_unit is not null when true then ' area-unit="'||self.area_unit||'"' else null end
          ||case self.velocity_unit is not null when true then ' velocity-unit="'||self.velocity_unit||'"' else null end
          ||' used="'||case self.used when 'T' then 'true' else 'false' end||'">';
      l_text := l_text ||make_elem('location',           self.location.get_location_id);
      l_text := l_text ||make_elem('number',             self.meas_number);
      l_text := l_text ||make_elem('date',               cwms_util.get_xml_time(self.date_time, self.time_zone));
      l_text := l_text ||make_elem('agency',             self.agency_id);
      l_text := l_text ||make_elem('party',              self.party);
      l_text := l_text ||make_elem('wm-comments',        self.wm_comments);
      l_text := l_text || '<stream-flow-measurement>';
      l_text := l_text ||make_elem('gage-height',        cwms_rounding.round_dt_f(self.gage_height, '9999999999'));
      l_text := l_text ||make_elem('flow',               cwms_rounding.round_dt_f(self.flow, '9999999999'));
      l_text := l_text ||make_elem('quality',            l_quality);
      l_text := l_text || '</stream-flow-measurement>';
      l_text := l_text || '<usgs-measurement>';
      l_text := l_text ||make_elem('current-rating',     self.cur_rating_num);
      l_text := l_text ||make_elem('shift-used',         cwms_rounding.round_dt_f(self.shift_used, '9999999999'));
      l_text := l_text ||make_elem('percent-difference', cwms_rounding.round_dt_f(self.pct_diff, '9999999999'));
      l_text := l_text ||make_elem('delta-height',       cwms_rounding.round_dt_f(self.delta_height, '9999999999'));
      l_text := l_text ||make_elem('delta-time',         cwms_rounding.round_dt_f(self.delta_time, '9999999999'));
      l_text := l_text ||make_elem('control-condition',  self.ctrl_cond_id);
      l_text := l_text ||make_elem('flow-adjustment',    self.flow_adj_id);
      l_text := l_text ||make_elem('remarks',            self.remarks);
      l_text := l_text ||make_elem('air-temp',           cwms_rounding.round_dt_f(self.air_temp, '9999999999'));
      l_text := l_text ||make_elem('water-temp',         cwms_rounding.round_dt_f(self.water_temp, '9999999999'));
      l_text := l_text || '</usgs-measurement>';
      -- Supplemental Stream Flow Measurement Section
      l_text := l_text || self.supp_streamflow_meas.to_xml;
      l_text := l_text || '</measurement>';
      return l_text;
   end to_string1;
end;
/
show errors;


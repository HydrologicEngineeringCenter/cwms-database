create or replace type body streamflow_meas_t 
as    
   constructor function streamflow_meas_t (
      p_rdb_line  in varchar2,
      p_office_id in varchar2 default null)
      return self as result
   is
      c_agency_cd                 constant pls_integer :=  1;
      c_site_no                   constant pls_integer :=  2;
      c_measurement_nu            constant pls_integer :=  3;
      c_measurement_dt            constant pls_integer :=  4;
      c_tz_cd                     constant pls_integer :=  5;
      c_q_meas_used_fg            constant pls_integer :=  6;
      c_party_nm                  constant pls_integer :=  7;
      c_site_visit_coll_agency_cd constant pls_integer :=  8;
      c_gage_height_va            constant pls_integer :=  9;
      c_discharge_va              constant pls_integer := 10;
      c_current_rating_nu         constant pls_integer := 11;
      c_shift_adj_va              constant pls_integer := 12;
      c_diff_from_rating_pc       constant pls_integer := 13;
      c_measured_rating_diff      constant pls_integer := 14;
      c_gage_va_change            constant pls_integer := 15;
      c_gage_va_time              constant pls_integer := 16;
      c_control_type_cd           constant pls_integer := 17;
      c_discharge_cd              constant pls_integer := 18;
      l_office_id varchar2(16);
      l_parts      str_tab_t;
      l_timestamp  timestamp;
      l_utc_offset interval day (0) to second (3);
   begin
      for i in 1..1 loop
         if p_rdb_line is null or substr(p_rdb_line, 1, 1) = '#' then
            exit;
         end if;
         l_parts := cwms_util.split_text(p_rdb_line, chr(9));
         if l_parts.count not in (18, 35) then
            cwms_err.raise(
               'ERROR',
               'Expected 18 or 35 fields in input, got '||l_parts.count||chr(10)||p_rdb_line);
         end if;
         if upper(l_parts(c_agency_cd)) != l_parts(c_agency_cd) then
             exit;
         end if;
         l_office_id         := cwms_util.get_db_office_id(p_office_id);
         self.location       := location_ref_t(cwms_loc.get_location_id(l_parts(c_site_no), l_office_id), l_office_id); 
         self.meas_number    := to_number(l_parts(c_measurement_nu));
         if length(l_parts(c_measurement_dt)) = 10 then
            -- date only 
            self.date_time   := to_date(l_parts(c_measurement_dt), 'yyyy-mm-dd');
            self.time_zone   := null;
         else            
            -- date, time, and tz
            l_timestamp      := to_timestamp(l_parts(c_measurement_dt), 'yyyy-mm-dd hh24:mi:ss');
            select tz_utc_offset
              into l_utc_offset
              from cwms_usgs_time_zone
             where tz_id = l_parts(c_tz_cd);
            self.date_time   := cast((l_timestamp - l_utc_offset) as date); 
         self.time_zone      := 'UTC';
         end if;
         self.used           := case when substr(l_parts(c_q_meas_used_fg), 1, 1) = 'Y' then 'T' else 'F' end;
         self.party          := l_parts(c_party_nm);                   
         self.agency_id      := l_parts(c_site_visit_coll_agency_cd);
         self.gage_height    := to_binary_double(l_parts(c_gage_height_va));
         self.flow           := to_binary_double(l_parts(c_discharge_va));
         self.cur_rating_num := l_parts(c_current_rating_nu);
         self.shift_used     := to_binary_double(l_parts(c_shift_adj_va));
         self.pct_diff       := to_binary_double(l_parts(c_diff_from_rating_pc));
         self.quality        := upper(substr(l_parts(c_measured_rating_diff), 1, 1));
         self.delta_height   := to_binary_double(l_parts(c_gage_va_change));
         self.delta_time     := to_binary_double(l_parts(c_gage_va_time)); 
         self.ctrl_cond_id   := l_parts(c_control_type_cd);
         self.flow_adj_id    := l_parts(c_discharge_cd);
         self.height_unit    := 'ft';
         self.flow_unit      := 'cfs';
         self.time_zone      := 'UTC';
      end loop; 
      return;
   end streamflow_meas_t;
      
   constructor function streamflow_meas_t (
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
      if p_xml.getrootelement != 'stream-flow-measurement' then
         cwms_err.raise(
            'ERROR',
            'Expected <stream-flow-measurement>, got <'||p_xml.getrootelement||'>');
      end if;
      self.location       := location_ref_t(get_text('/*/location', true), get_text('/*/@office-id', true));
      self.used           := case get_text('/*/@used', true) when 'true' then 'T' else 'F' end;
      self.height_unit    := get_text('/*/@height-unit', self.used='T');       
      self.flow_unit      := get_text('/*/@flow-unit', self.used='T');
      self.meas_number    := to_number(get_text('/*/number', true));  
      self.date_time      := cast(cwms_util.to_timestamp(get_text('/*/date', true)) as date);
      self.agency_id      := get_text('/*/agency');     
      self.party          := get_text('/*/party');
      self.gage_height    := to_binary_double(get_text('/*/gage-height', self.used='T'));
      self.flow           := to_binary_double(get_text('/*/flow', self.used='T'));
      self.cur_rating_num := get_text('/*/current-rating');
      self.shift_used     := to_binary_double(get_text('/*/shift-used'));
      self.pct_diff       := to_binary_double(get_text('/*/percent-difference')); 
      self.quality        := substr(upper(trim(get_text('/*/quality'))),1,1);
      self.delta_height   := to_binary_double(get_text('/*/delta-height'));
      self.delta_time     := to_binary_double(get_text('/*/delta-time'));
      self.ctrl_cond_id   := get_text('/*/control-condition');
      self.flow_adj_id    := get_text('/*/flow-adjustment');
      self.remarks        := get_text('/*/remarks');
      return;
   end streamflow_meas_t;       
      
   constructor function streamflow_meas_t (
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
         
      self := new streamflow_meas_t(l_rowid);           
      return;
   end streamflow_meas_t;      
      
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_meas_number in integer,
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
         
      self := new streamflow_meas_t(l_rowid);           
      return;
   end streamflow_meas_t;
      
   constructor function streamflow_meas_t (
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
      self.time_zone       := 'UTC';
      self.height_unit     := cwms_util.get_default_units('Stage', p_unit_system);
      self.flow_unit       := cwms_util.get_default_units('Flow', p_unit_system);          
      self.meas_number     := l_rec.meas_number;
      self.date_time       := l_rec.date_time;
      self.used            := l_rec.used;
      self.agency_id       := l_rec.agency_id;
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
      return;       
   end streamflow_meas_t;      

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
   begin
      l_rec.location_code := self.location.get_location_code;
      l_rec.meas_number   := self.meas_number;
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
      l_rec.date_time      := cwms_util.change_timezone(self.date_time, nvl(self.time_zone, cwms_loc.get_local_timezone(self.location.get_location_code)), 'UTC');
      l_rec.used           := self.used;
      l_rec.party          := self.party;
      l_rec.agency_id      := self.agency_id;
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
      l_text := '<stream-flow-measurement'
                ||' office-id="'||self.location.office_id||'"'
                ||' height-unit="'||self.height_unit||'"'
                ||' flow-unit="'||self.flow_unit||'"'
                ||' used="'||case self.used when 'T' then 'true' else 'false' end||'">';
      l_text := l_text ||make_elem('location',           self.location.get_location_id);                
      l_text := l_text ||make_elem('number',             self.meas_number);                
      l_text := l_text ||make_elem('date',               cwms_util.get_xml_time(self.date_time, self.time_zone));                
      l_text := l_text ||make_elem('agency',             self.agency_id);                
      l_text := l_text ||make_elem('party',              self.party);                
      l_text := l_text ||make_elem('gage-height',        cwms_rounding.round_dt_f(self.gage_height, '9999999999'));                
      l_text := l_text ||make_elem('flow',               cwms_rounding.round_dt_f(self.flow, '9999999999'));                
      l_text := l_text ||make_elem('current-rating',     self.cur_rating_num);                
      l_text := l_text ||make_elem('shift-used',         cwms_rounding.round_dt_f(self.shift_used, '9999999999'));                
      l_text := l_text ||make_elem('percent-difference', cwms_rounding.round_dt_f(self.pct_diff, '9999999999'));                
      l_text := l_text ||make_elem('quality',            l_quality);                
      l_text := l_text ||make_elem('delta-height',       cwms_rounding.round_dt_f(self.delta_height, '9999999999'));                
      l_text := l_text ||make_elem('delta-time',         cwms_rounding.round_dt_f(self.delta_time, '9999999999'));                
      l_text := l_text ||make_elem('control-condition',  self.ctrl_cond_id);                
      l_text := l_text ||make_elem('flow-adjustment',    self.flow_adj_id);                
      l_text := l_text ||make_elem('remarks',            self.remarks);                
      l_text := l_text || '</stream-flow-measurement>';
      Return L_Text;            
   end to_string1;
end;
/
show errors;


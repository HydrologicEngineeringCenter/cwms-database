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
               'Expected 18 or 35 fields in input, got '||l_parts.count);
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
         self.velocity_unit  := 'ft/s';
      end loop; 
      return;
   end streamflow_meas_t;
      
   constructor function streamflow_meas_t (
      p_xml in xmltype)
      return self as result
   is
   begin
      return;
   end streamflow_meas_t;       
      
   constructor function streamflow_meas_t (
      p_location      in location_ref_t,
      p_date_time_utc in date,
      p_time_zone     in varchar2 default 'UTC')
      return self as result
   is
   begin
      return;
   end streamflow_meas_t;      
      
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_meas_number in integer,
      p_time_zone   in varchar2 default 'UTC')
      return self as result
   is
   begin
      return;
   end streamflow_meas_t;
      
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
      l_rec.shift_used     := cwms_util.convert_units(self.shift_used, self.height_unit, 'm');
      l_rec.quality        := self.quality;
      l_rec.delta_height   := cwms_util.convert_units(self.delta_height, self.height_unit, 'm');
      l_rec.delta_time     := self.delta_time;
      l_rec.ctrl_cond_id   := self.ctrl_cond_id;
      l_rec.flow_adj_id    := self.flow_adj_id;
      l_rec.outside_height := cwms_util.convert_units(self.outside_height, self.height_unit, 'm');
      l_rec.velocity       := cwms_util.convert_units(self.velocity, self.velocity_unit, 'kph');
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
      l_xml xmltype;
   begin
      return l_xml;
   end to_xml;
      
   member function to_string
      return varchar2
   is  
      l_xml xmltype;
   begin            
      l_xml := self.to_xml;
      return l_xml.getstringval;
   end to_string;
end;
/
show errors;


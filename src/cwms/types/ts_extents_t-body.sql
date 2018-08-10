create or replace type body ts_extents_t
as
   constructor function ts_extents_t(
      p_rowid in urowid)
      return self as result
   is
      l_ts_extents at_ts_extents%rowtype;
   begin
      select * into l_ts_extents from at_ts_extents where rowid = p_rowid;
      self.ts_code                       := l_ts_extents.ts_code;                      
      self.version_time                  := l_ts_extents.version_time;                 
      self.earliest_time                 := l_ts_extents.earliest_time;                
      self.earliest_time_entry           := l_ts_extents.earliest_time_entry;          
      self.earliest_entry_time           := l_ts_extents.earliest_entry_time;          
      self.earliest_non_null_time        := l_ts_extents.earliest_non_null_time;       
      self.earliest_non_null_time_entry  := l_ts_extents.earliest_non_null_time_entry; 
      self.earliest_non_null_entry_time  := l_ts_extents.earliest_non_null_entry_time; 
      self.latest_time                   := l_ts_extents.latest_time;                  
      self.latest_time_entry             := l_ts_extents.latest_time_entry;            
      self.latest_entry_time             := l_ts_extents.latest_entry_time;            
      self.latest_non_null_time          := l_ts_extents.latest_non_null_time;         
      self.latest_non_null_time_entry    := l_ts_extents.latest_non_null_time_entry;   
      self.latest_non_null_entry_time    := l_ts_extents.latest_non_null_entry_time;   
      self.least_value                   := l_ts_extents.least_value;             
      self.least_value_time              := l_ts_extents.least_value_time;             
      self.least_value_entry             := l_ts_extents.least_value_entry;            
      self.least_accepted_value          := l_ts_extents.least_accepted_value;    
      self.least_accepted_value_time     := l_ts_extents.least_accepted_value_time;    
      self.least_accepted_value_entry    := l_ts_extents.least_accepted_value_entry;   
      self.greatest_value                := l_ts_extents.greatest_value;          
      self.greatest_value_time           := l_ts_extents.greatest_value_time;          
      self.greatest_value_entry          := l_ts_extents.greatest_value_entry;         
      self.greatest_accepted_value       := l_ts_extents.greatest_accepted_value; 
      self.greatest_accepted_value_time  := l_ts_extents.greatest_accepted_value_time; 
      self.greatest_accepted_value_entry := l_ts_extents.greatest_accepted_value_entry;
      self.last_update                   := l_ts_extents.last_update;
      return;
   end ts_extents_t;
   
   member procedure convert_units(
      p_from_unit in varchar2 default null,
      p_to_unit   in varchar2 default null)
   is
      l_from_unit varchar2(16) := p_from_unit;
      l_to_unit   varchar2(16) := p_to_unit;
      l_parameter varchar2(49);
   begin
      if l_from_unit is null or l_to_unit is null then
         select parameter_id into l_parameter from at_cwms_ts_id where ts_code = self.ts_code;
         if l_from_unit is null then
            l_from_unit := cwms_util.get_default_units(l_parameter);
         end if;
         if l_to_unit is null then
            l_to_unit := cwms_util.get_default_units(l_parameter);
         end if;
      end if;
      if l_to_unit != l_from_unit then
         self.least_value             := cwms_util.convert_units(self.least_value,             l_from_unit, l_to_unit);
         self.least_accepted_value    := cwms_util.convert_units(self.least_accepted_value,    l_from_unit, l_to_unit);
         self.greatest_value          := cwms_util.convert_units(self.greatest_value,          l_from_unit, l_to_unit);
         self.greatest_accepted_value := cwms_util.convert_units(self.greatest_accepted_value, l_from_unit, l_to_unit);
      end if;
   end convert_units;

   member procedure change_timezone(
      p_from_timezone in varchar2 default null,
      p_to_timezone   in varchar2 default null)
   is
      l_from_timezone varchar2(28) := nvl(p_from_timezone, 'UTC');
      l_to_timezone   varchar2(28) := nvl(p_to_timezone,   'UTC');
   begin
      if upper(l_from_timezone) = 'LOCAL' then
         select tz.time_zone_name
           into l_from_timezone
           from at_cwms_ts_spec ts,
                at_physical_location pl,
                cwms_time_zone tz
          where ts.ts_code = self.ts_code
            and pl.location_code = ts.location_code
            and tz.time_zone_code = pl.time_zone_code;
      end if;
      if upper(l_to_timezone) = 'LOCAL' then
         select tz.time_zone_name
           into l_to_timezone
           from at_cwms_ts_spec ts,
                at_physical_location pl,
                cwms_time_zone tz
          where ts.ts_code = self.ts_code
            and pl.location_code = ts.location_code
            and tz.time_zone_code = pl.time_zone_code;
      end if;
      if l_to_timezone != l_from_timezone then
         self.version_time                  := cwms_util.change_timezone(self.version_time,                  l_from_timezone, l_to_timezone);
         self.earliest_time                 := cwms_util.change_timezone(self.earliest_time,                 l_from_timezone, l_to_timezone);
         self.earliest_time_entry           := cwms_util.change_timezone(self.earliest_time_entry,           l_from_timezone, l_to_timezone);
         self.earliest_entry_time           := cwms_util.change_timezone(self.earliest_entry_time,           l_from_timezone, l_to_timezone);
         self.earliest_non_null_time        := cwms_util.change_timezone(self.earliest_non_null_time,        l_from_timezone, l_to_timezone);
         self.earliest_non_null_time_entry  := cwms_util.change_timezone(self.earliest_non_null_time_entry,  l_from_timezone, l_to_timezone);
         self.earliest_non_null_entry_time  := cwms_util.change_timezone(self.earliest_non_null_entry_time,  l_from_timezone, l_to_timezone);
         self.latest_time                   := cwms_util.change_timezone(self.latest_time,                   l_from_timezone, l_to_timezone);
         self.latest_time_entry             := cwms_util.change_timezone(self.latest_time_entry,             l_from_timezone, l_to_timezone);
         self.latest_entry_time             := cwms_util.change_timezone(self.latest_entry_time,             l_from_timezone, l_to_timezone);
         self.latest_non_null_time          := cwms_util.change_timezone(self.latest_non_null_time,          l_from_timezone, l_to_timezone);
         self.latest_non_null_time_entry    := cwms_util.change_timezone(self.latest_non_null_time_entry,    l_from_timezone, l_to_timezone);
         self.latest_non_null_entry_time    := cwms_util.change_timezone(self.latest_non_null_entry_time,    l_from_timezone, l_to_timezone);
         self.least_value_time              := cwms_util.change_timezone(self.least_value_time,              l_from_timezone, l_to_timezone);
         self.least_value_entry             := cwms_util.change_timezone(self.least_value_entry,             l_from_timezone, l_to_timezone);
         self.least_accepted_value_time     := cwms_util.change_timezone(self.least_accepted_value_time,     l_from_timezone, l_to_timezone);
         self.least_accepted_value_entry    := cwms_util.change_timezone(self.least_accepted_value_entry,    l_from_timezone, l_to_timezone);
         self.greatest_value_time           := cwms_util.change_timezone(self.greatest_value_time,           l_from_timezone, l_to_timezone);
         self.greatest_value_entry          := cwms_util.change_timezone(self.greatest_value_entry,          l_from_timezone, l_to_timezone);
         self.greatest_accepted_value_time  := cwms_util.change_timezone(self.greatest_accepted_value_time,  l_from_timezone, l_to_timezone);
         self.greatest_accepted_value_entry := cwms_util.change_timezone(self.greatest_accepted_value_entry, l_from_timezone, l_to_timezone);
         self.last_update                   := cwms_util.change_timezone(self.last_update,                   l_from_timezone, l_to_timezone);
      end if;
   end change_timezone;
end;                 
/
show errors;

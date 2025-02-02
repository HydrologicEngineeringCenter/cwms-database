create or replace type body location_obj_t
as

   constructor function location_obj_t(
      p_location_ref in location_ref_t)
      return self as result
   is
   begin
      begin
         self.init(p_location_ref.get_location_code);
      exception
         when no_data_found then
            self.location_ref := p_location_ref;
      end;
      return;
   end;
   
   constructor function location_obj_t(
      p_location_code in number)
      return self as result
   is
   begin
      self.init(p_location_code);
      return;
   end;      

   member procedure init(
      p_location_code in number)
   is
   begin
      for rec in 
         (  select l.location_code,
                   l.base_location_id,
                   l.sub_location_id,
                   s.state_initial,
                   s.county_name,
                   tz.time_zone_name,
                   l.location_type,
                   l.latitude,
                   l.longitude,
                   l.horizontal_datum,
                   l.elevation,
                   l.vertical_datum,
                   l.public_name,
                   l.long_name,
                   l.description,
                   l.active_flag,
                   lk.location_kind_id,
                   l.map_label,
                   l.published_latitude,
                   l.published_longitude,
                   o.office_id as bounding_office_id,
                   o.public_name as bounding_office_name,
                   n.long_name as nation_id,
                   l.nearest_city
              from ( select pl.location_code,
                            bl.base_location_id,
                            pl.sub_location_id,
                            pl.time_zone_code,
                            pl.county_code,
                            pl.location_type,
                            pl.elevation,
                            pl.vertical_datum,
                            pl.longitude,
                            pl.latitude,
                            pl.horizontal_datum,
                            pl.public_name,
                            pl.long_name,
                            pl.description,
                            pl.active_flag,
                            pl.location_kind,
                            pl.map_label,
                            pl.published_latitude,
                            pl.published_longitude,
                            pl.office_code,
                            pl.nation_code,
                            pl.nearest_city                
                       from at_physical_location pl,
                            at_base_location     bl
                      where bl.base_location_code = pl.base_location_code
                        and pl.location_code = p_location_code
                   ) l
                   left outer join
                   ( select county_code,
                            county_name,
                            state_initial
                       from cwms_county,
                            cwms_state
                      where cwms_state.state_code = cwms_county.state_code
                   ) s on s.county_code = l.county_code
                   left outer join cwms_time_zone   tz on tz.time_zone_code = l.time_zone_code
                   left outer join cwms_location_kind lk on lk.location_kind_code = l.location_kind
                   left outer join cwms_office      o  on o.office_code = l.office_code
                   left outer join cwms_nation_sp   n  on n.fips_cntry = l.nation_code
         )   
      loop
         self.location_ref         := location_ref_t(p_location_code);
         self.state_initial        := rec.state_initial;
         self.county_name          := rec.county_name;
         self.time_zone_name       := rec.time_zone_name;
         self.location_type        := rec.location_type;
         self.latitude             := rec.latitude;
         self.longitude            := rec.longitude;
         self.horizontal_datum     := rec.horizontal_datum;
         self.elevation            := rec.elevation;
         self.elev_unit_id         := 'm';
         self.vertical_datum       := rec.vertical_datum;
         self.public_name          := rec.public_name;
         self.long_name            := rec.long_name;
         self.description          := rec.description;
         self.active_flag          := rec.active_flag;
         self.location_kind_id     := rec.location_kind_id;
         self.map_label            := rec.map_label;
         self.published_latitude   := rec.published_latitude;
         self.published_longitude  := rec.published_longitude;
         self.bounding_office_id   := rec.bounding_office_id;
         self.bounding_office_name := rec.bounding_office_name;
         self.nation_id            := rec.nation_id;
         self.nearest_city         := rec.nearest_city;
      end loop;
   end;      
      
end;
/
show errors;

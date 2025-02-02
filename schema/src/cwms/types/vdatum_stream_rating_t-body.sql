create or replace type body vdatum_stream_rating_t
as                           
   constructor function vdatum_stream_rating_t(
      p_rating         in stream_rating_t,
      p_current_datum  in varchar2
   ) return self as result
   is
   begin
      ------------------------------
      -- initialize from p_rating --
      ------------------------------
      (self as stream_rating_t).init(p_rating);
      ---------------------------
      -- finish initialization --
      ---------------------------
      self.current_datum  := p_current_datum;
      self.elev_position  := 1; -- only and always
      return;
   end;
   
   constructor function vdatum_stream_rating_t(
      p_other in vdatum_stream_rating_t
   ) return self as result
   is
   begin
      ------------------------------
      -- initialize from p_rating --
      ------------------------------
      (self as stream_rating_t).init(p_other);
      ---------------------------
      -- finish initialization --
      ---------------------------
      self.native_datum  := p_other.native_datum;
      self.current_datum := p_other.current_datum;
      self.elev_position := 1; -- only and always
      return;
   end;
   
   member procedure to_vertical_datum(
      p_vertical_datum in varchar2)
   is                         
      l_parts     str_tab_t;
      l_dep_unit  varchar2(16);
      l_ind_units str_tab_t;
      l_elev_unit varchar2(16);
      l_offset    binary_double;
      l_temp      rating_t;
   begin   
      if self.current_datum != upper(p_vertical_datum) then
         if self.current_units = 'D' then
            l_elev_unit := 'm';
         else
            l_elev_unit := l_ind_units(1);
         end if;
         l_offset := cwms_loc.get_vertical_datum_offset(
            p_location_id         => cwms_util.split_text(self.rating_spec_id, 1, cwms_rating.separator1), 
            p_vertical_datum_id_1 => self.current_datum, 
            p_vertical_datum_id_2 => p_vertical_datum, 
            p_unit                => l_elev_unit, 
            p_office_id           => self.office_id);
         self.rating_info.add_offset(l_offset, self.elev_position);
         if self.offsets is not null and self.offsets.rating_info is not null then
            self.offsets.rating_info.add_offset(l_offset, self.elev_position);
         end if;
         self.current_datum := upper(p_vertical_datum);
         if self.shifts is not null then
            for i in 1..self.shifts.count loop
               l_temp := treat(self.shifts(i) as rating_t);
               if l_temp is not null and l_temp.rating_info is not null then
                  l_temp.rating_info.add_offset(l_offset, self.elev_position);
               end if;
            end loop;
         end if;
         self.current_datum := p_vertical_datum;
      end if;
   end;
   
   member procedure to_native_datum
   is
   begin
      self.to_vertical_datum(
         cwms_loc.get_location_vertical_datum(
            cwms_util.split_text(self.rating_spec_id, 1, cwms_rating.separator1), 
            self.office_id));
   end;
   
   overriding member function to_clob(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return clob
   is
      l_clob        clob;
      l_clone       vdatum_stream_rating_t;
      l_location_id varchar2(57);
      l_local_datum varchar2(16);
   begin           
      l_clone := self;
      l_location_id := cwms_util.split_text(l_clone.rating_spec_id, 1, cwms_rating.separator1);
      l_clob := (l_clone as stream_rating_t).to_clob(p_timezone, p_units, p_vert_datum);
      l_local_datum := cwms_loc.get_location_vertical_datum(l_location_id, l_clone.office_id);
      if l_local_datum is null then
         l_clob := replace(l_clob, '</rating-spec-id>', '</rating-spec-id><vertical-datum/>');
      else     
         l_clone.to_native_datum;
         l_clob := replace(l_clob, '</rating-spec-id>', '</rating-spec-id><vertical-datum>'||l_local_datum||'</vertical-datum>');
      end if;   
      return l_clob;
   end;
   
   overriding member function to_xml(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return xmltype
   is
   begin
      return xmltype(self.to_clob(p_timezone, p_units, p_vert_datum));
   end;
         
end;
/
show errors  

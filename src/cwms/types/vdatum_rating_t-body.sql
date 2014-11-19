create or replace type body vdatum_rating_t 
as
   constructor function vdatum_rating_t(
      p_rating         in rating_t,
      p_current_datum  in varchar2,
      p_elev_positions in number_tab_t
   ) return self as result
   is
   begin 
      ------------------------------
      -- initialize from p_rating --
      ------------------------------
      self.office_id      := p_rating.office_id;
      self.rating_spec_id := p_rating.rating_spec_id;
      self.effective_date := p_rating.effective_date;
      self.create_date    := p_rating.create_date;
      self.active_flag    := p_rating.active_flag;
      self.formula        := p_rating.formula;
      self.native_units   := p_rating.native_units;
      self.description    := p_rating.description;
      self.rating_info    := p_rating.rating_info;
      self.current_units  := p_rating.current_units;
      self.current_time   := p_rating.current_time;
      self.formula_tokens := p_rating.formula_tokens;
      ---------------------------
      -- finish initialization --
      ---------------------------
      self.current_datum  := p_current_datum;
      self.elev_positions := p_elev_positions;
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
   begin   
      if self.current_datum != upper(p_vertical_datum) then
         if self.formula is not null then
            cwms_err.raise('ERROR', 'Can''t change vertical datum on a formula rating.');
         end if;
         for i in 1..self.elev_positions.count loop
            if self.current_units = 'D' then
               l_elev_unit := 'm';
            else
               if l_parts is null then
                  l_parts     := cwms_util.split_text(self.native_units, cwms_rating.separator2);
                  l_dep_unit  := l_parts(2);
                  l_ind_units := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
               end if;
               if self.elev_positions(i) = -1 then
                  l_elev_unit := l_dep_unit;
               else                                      
                  l_elev_unit := l_ind_units(self.elev_positions(i));
               end if;
            end if;
            l_offset := cwms_loc.get_vertical_datum_offset(
               p_location_id         => cwms_util.split_text(self.rating_spec_id, 1, cwms_rating.separator1), 
               p_vertical_datum_id_1 => self.current_datum, 
               p_vertical_datum_id_2 => p_vertical_datum, 
               p_unit                => l_elev_unit, 
               p_office_id           => self.office_id);
            self.rating_info.add_offset(l_offset, self.elev_positions(i));
         end loop;
         self.current_datum := upper(p_vertical_datum);
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
   
   overriding member function to_clob
      return clob
   is
      l_clob        clob;
      l_clone       vdatum_rating_t;
      l_location_id varchar2(49);
      l_local_datum varchar2(16);
      l_parts       str_tab_t;  
      l_unit_id     varchar2(16);
      l_vdatum_info varchar2(32767);
   begin
      if self.current_datum != self.native_datum then
         l_clone := self;
         l_clone.to_native_datum;
      else 
         l_clob := (self as rating_t).to_clob;
         l_location_id := cwms_util.split_text(self.rating_spec_id, 1, cwms_rating.separator1);
         l_local_datum := cwms_loc.get_location_vertical_datum(l_location_id, self.office_id);
         l_parts       := cwms_util.split_text(replace(self.native_units, cwms_rating.separator2, cwms_rating.separator3), cwms_rating.separator3);
         if self.elev_positions(1) = -1 then
            l_unit_id := l_parts(l_parts.count);
         else
            l_unit_id := l_parts(self.elev_positions(1));
         end if; 
         l_vdatum_info := cwms_loc.get_vertical_datum_info_f(l_location_id, l_unit_id, self.office_id);
         l_vdatum_info := regexp_replace(l_vdatum_info, '\s+office="\w+"', null); 
         l_vdatum_info := regexp_replace(l_vdatum_info, '<location>.+</location>', null); 
         l_vdatum_info := regexp_replace(l_vdatum_info, '(>)\s+(\S)', '\1\2'); 
         l_vdatum_info := regexp_replace(l_vdatum_info, '(\S)\s+(<)', '\1\2'); 
         l_clob := replace(
            l_clob, 
            '</rating-spec-id>', 
            '</rating-spec-id>'||l_vdatum_info);
      end if;
      return l_clob;
   end;
      
   overriding member function to_xml
      return xmltype      
   is
   begin
      return xmltype(to_clob);
   end;
   
end;
/
show errors;

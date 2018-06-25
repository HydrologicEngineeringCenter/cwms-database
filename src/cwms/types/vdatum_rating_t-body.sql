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
      (self as rating_t).init(p_rating);
      ---------------------------
      -- finish initialization --
      ---------------------------
      self.native_datum   := cwms_loc.get_location_vertical_datum(cwms_util.split_text(self.rating_spec_id, 1, cwms_rating.separator1), self.office_id);
      self.current_datum  := p_current_datum;
      self.elev_positions := p_elev_positions;
      return;
   end;
          
      constructor function vdatum_rating_t(
      p_other in vdatum_rating_t
   ) return self as result
   is
   begin
      (self as rating_t).init(p_other);
      self.native_datum   := p_other.native_datum;
      self.current_datum  := p_other.current_datum;
      self.elev_positions := p_other.elev_positions;
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
      self.to_vertical_datum(self.native_datum);
   end;      
   
   overriding member function to_clob(
      self         in out nocopy vdatum_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return clob
   is
      l_clone       vdatum_rating_t;       
      l_vert_datum  varchar2(32);
      l_clob        clob;
      l_location_id varchar2(57);
      l_parts       str_tab_t;  
      l_unit_id     varchar2(16);
      l_vdatum_info varchar2(32767);
   begin                            
      l_clone := self;
      l_vert_datum := upper(trim(p_vert_datum));
      if l_vert_datum = 'NATIVE' then
         l_clone.to_native_datum;
         l_clone.current_datum := l_clone.native_datum;
      else
         l_clone.to_vertical_datum(l_vert_datum);
         l_clone.current_datum := l_vert_datum;
      end if;
      l_clob := (l_clone as rating_t).to_clob(p_timezone, p_units, p_vert_datum);
      l_location_id := cwms_util.split_text(l_clone.rating_spec_id, 1, '.');
      case
         when p_units is null or p_units = 'NATIVE' then
            l_parts       := cwms_util.split_text(replace(l_clone.native_units, ';', ','), ',');
            if l_clone.elev_positions(1) = -1 then
               l_unit_id := l_parts(l_parts.count);
            else
               l_unit_id := l_parts(l_clone.elev_positions(1));
            end if;
         when p_units in ('EN', 'SI') then
            l_unit_id := cwms_util.get_default_units('Elev', p_units);
         else    
            l_parts       := cwms_util.split_text(replace(p_units, ';', ','), ',');
            if l_clone.elev_positions(1) = -1 then
               l_unit_id := l_parts(l_parts.count);
            else
               l_unit_id := l_parts(l_clone.elev_positions(1));
            end if;
      end case;     
      ------------------------------- 
      -- handle the vertical datum --
      -------------------------------     
      l_vdatum_info := cwms_loc.get_vertical_datum_info_f(l_location_id, l_unit_id, l_clone.office_id); 
      l_vdatum_info := regexp_replace(l_vdatum_info, '\s+office="\w+"', null); 
      l_vdatum_info := regexp_replace(l_vdatum_info, '<location>.+</location>', null); 
      l_vdatum_info := regexp_replace(l_vdatum_info, '(>)\s+(\S)', '\1\2'); 
      l_vdatum_info := regexp_replace(l_vdatum_info, '(\S)\s+(<)', '\1\2'); 
      l_clob := replace(l_clob, '</rating-spec-id>', '</rating-spec-id>'||l_vdatum_info);  
      l_clob := replace(l_clob, '<units-id>', '<units-id vertical-datum="'||l_clone.current_datum||'">');         
      return l_clob;
   end;
      
   overriding member function to_xml(
      self         in out nocopy vdatum_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return xmltype      
   is
   begin
      return xmltype(to_clob((self as rating_t), p_timezone, p_units, p_vert_datum));
   end;
   
end;
/
show errors;

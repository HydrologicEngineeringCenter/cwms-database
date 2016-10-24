create or replace type body zloc_lvl_indicator_t
as
   constructor function zloc_lvl_indicator_t
      return self as result
   is
   begin
      return;
   end zloc_lvl_indicator_t;

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
      l_parameter_code    number(10);
      l_vert_datum_offset binary_double;
   begin
      conditions := new loc_lvl_ind_cond_tab_t();
      select level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
       into  level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
        from at_loc_lvl_indicator
       where rowid = p_rowid;
      begin
        select ap.parameter_code
          into l_parameter_code
          from at_parameter ap,
               cwms_base_parameter bp
         where ap.parameter_code = self.attr_parameter_code
           and bp.base_parameter_code = ap.base_parameter_code
           and bp.base_parameter_id = 'Elev';
      exception
        when no_data_found then null;
      end;
      if l_parameter_code is not null then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
         self.attr_value := self.attr_value + l_vert_datum_offset;
         self.ref_attr_value := self.ref_attr_value + l_vert_datum_offset;
      end if;
      for rec in (select rowid
                    from at_loc_lvl_indicator_cond
                   where level_indicator_code = self.level_indicator_code
                order by level_indicator_value)
      loop
         conditions.extend;
         conditions(conditions.count) := loc_lvl_indicator_cond_t(rec.rowid);
         if conditions(conditions.count).comparison_unit is not null then
            ------------------------------------------------------------------------
            -- set factor and offset to convert from db units to comparison units --
            ------------------------------------------------------------------------
            select factor,
                   offset
              into conditions(conditions.count).factor,
                   conditions(conditions.count).offset
              from at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit_conversion uc
             where p.parameter_code = self.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and uc.from_unit_code = bp.unit_code
               and uc.to_unit_code = conditions(conditions.count).comparison_unit;
         end if;
         if conditions(conditions.count).rate_interval is not null then
            if conditions(conditions.count).rate_comparison_unit is not null then
               ----------------------------------------------------------------------------------
               -- set rate_factor and rate_offset to convert from db units to comparison units --
               ----------------------------------------------------------------------------------
               select factor,
                      offset
                 into conditions(conditions.count).rate_factor,
                      conditions(conditions.count).rate_offset
                 from at_parameter p,
                      cwms_base_parameter bp,
                      cwms_unit_conversion uc
                where p.parameter_code = self.parameter_code
                  and bp.base_parameter_code = p.base_parameter_code
                  and uc.from_unit_code = bp.unit_code
                  and uc.to_unit_code = conditions(conditions.count).rate_comparison_unit;
            end if;
            -----------------------------------------------------------------
            -- set interval_factor to convert from 1 hour to rate interval --
            -----------------------------------------------------------------
            conditions(conditions.count).interval_factor := 24 *
               (extract(day    from conditions(conditions.count).rate_interval)        +
                extract(hour   from conditions(conditions.count).rate_interval) / 24   +
                extract(minute from conditions(conditions.count).rate_interval) / 3600 +
                extract(second from conditions(conditions.count).rate_interval) / 86400);
         end if;
      end loop;
      return;
   end zloc_lvl_indicator_t;

   member procedure store
   is
   begin
      cwms_level.store_loc_lvl_indicator_out(
         level_indicator_code,
         location_code,
         parameter_code,
         parameter_type_code,
         duration_code,
         specified_level_code,
         level_indicator_id,
         attr_value,
         attr_parameter_code,
         attr_parameter_type_code,
         attr_duration_code,
         ref_specified_level_code,
         ref_attr_value,
         minimum_duration,
         maximum_age,
         'F',
         'F');
      for i in 1..conditions.count loop
         conditions(i).store(level_indicator_code);
      end loop;
   end store;
end;
/
show errors;

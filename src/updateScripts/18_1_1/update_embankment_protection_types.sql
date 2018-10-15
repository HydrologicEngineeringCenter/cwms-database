declare
   l_matching_code    integer;
   l_cwms_office_code integer;
   l_host_office_code integer;
begin
   --------------------------
   -- get the office codes --
   --------------------------
   l_cwms_office_code := cwms_util.db_office_code_all;
   begin
      select office_code
        into l_host_office_code
        from cwms_office
       where eroc = (select substr(db_unique_name, 1, 2) from v$database);
   exception
      when no_data_found then null;
   end;
   -------------------------------
   -- insert the common records --
   -------------------------------
   insert into at_embank_protection_type values(1, l_cwms_office_code, 'Concrete Blanket',    'Protected by blanket of concrete',              'T');
   insert into at_embank_protection_type values(2, l_cwms_office_code, 'Concrete Arch Facing','Protected by the faces of the concrete arches', 'T');
   insert into at_embank_protection_type values(3, l_cwms_office_code, 'Masonry Facing',      'Protected by masonry facing',                   'T');
   insert into at_embank_protection_type values(4, l_cwms_office_code, 'Grass-Covered Soil',  'Protected by grass-covered soil',               'T');
   insert into at_embank_protection_type values(5, l_cwms_office_code, 'Soil Cement',         'Protected by soil cement',                      'T');
   insert into at_embank_protection_type values(6, l_cwms_office_code, 'Rock Riprap',         'Protected by rock riprap',                      'T');
   insert into at_embank_protection_type values(7, l_cwms_office_code, 'Natural Rock',        'Protected by natural rock',                     'T');
   insert into at_embank_protection_type values(8, l_cwms_office_code, 'Stone Toe',           'Protected by a stone toe',                      'T');

   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_embank_protection_type
                   where db_office_code = l_cwms_office_code 
                   order by protection_type_code
                 )
      loop
         -------------------------------
         -- get the local record code --
         -------------------------------
         begin
            select protection_type_code
              into l_matching_code
              from at_embank_protection_type
             where protection_type_display_value = rec.protection_type_display_value
               and db_office_code = l_host_office_code;
         exception
            when no_data_found then continue;
         end;   
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_embankment
            set upstream_prot_type_code = rec.protection_type_code
          where upstream_prot_type_code = l_matching_code;  
            
         update at_embankment
            set downstream_prot_type_code = rec.protection_type_code
          where downstream_prot_type_code = l_matching_code;
         -----------------------------
         -- delete the local record --
         -----------------------------
         delete
           from at_embank_protection_type
          where protection_type_code = l_matching_code; 
      end loop;
   end if;
end;   
/

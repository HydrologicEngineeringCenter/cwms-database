-------------------------------
-- insert the common records --
-------------------------------
insert into at_embank_protection_type values(1, 53, 'Concrete Blanket',    'Protected by blanket of concrete',              'T');
insert into at_embank_protection_type values(2, 53, 'Concrete Arch Facing','Protected by the faces of the concrete arches', 'T');
insert into at_embank_protection_type values(3, 53, 'Masonry Facing',      'Protected by masonry facing',                   'T');
insert into at_embank_protection_type values(4, 53, 'Grass-Covered Soil',  'Protected by grass-covered soil',               'T');
insert into at_embank_protection_type values(5, 53, 'Soil Cement',         'Protected by soil cement',                      'T');
insert into at_embank_protection_type values(6, 53, 'Rock Riprap',         'Protected by rock riprap',                      'T');
insert into at_embank_protection_type values(7, 53, 'Natural Rock',        'Protected by natural rock',                     'T');
insert into at_embank_protection_type values(8, 53, 'Stone Toe',           'Protected by a stone toe',                      'T');
commit;
declare
   l_matching_code    integer;
begin
   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select *
                 from at_embank_protection_type
                where db_office_code = cwms_util.db_office_code_all
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
            and db_office_code != cwms_util.db_office_code_all;
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
end;
/

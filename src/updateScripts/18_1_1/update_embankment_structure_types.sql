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
   insert into at_embank_structure_type values(1, l_cwms_office_code, 'Rolled Earth-Filled',      'An embankment formed by compacted earth',                                'T');
   insert into at_embank_structure_type values(2, l_cwms_office_code, 'Natural',                  'A natural embankment',                                                   'T');
   insert into at_embank_structure_type values(3, l_cwms_office_code, 'Concrete Arch',            'An embankment formed by concrete arches',                                'T');
   insert into at_embank_structure_type values(4, l_cwms_office_code, 'Dble-Curv Concrete Arch',  'An embankment formed by thin, double-curvature concrete arches',         'T');
   insert into at_embank_structure_type values(5, l_cwms_office_code, 'Concrete Apron',           'An embankment formed by a concrete apron',                               'T');
   insert into at_embank_structure_type values(6, l_cwms_office_code, 'Concrete Dam',             'An embankment formed by concrete',                                       'T');
   insert into at_embank_structure_type values(7, l_cwms_office_code, 'Concrete Gravity',         'An embankment formed by concrete gravity materials',                     'T');
   insert into at_embank_structure_type values(8, l_cwms_office_code, 'Rolld Imperv Earth-Fill',  'An embankment formed by rolled impervious and random earth-fill',        'T');
   insert into at_embank_structure_type values(9, l_cwms_office_code, 'Imprv/Semiperv EarthFill', 'An embankment formed by rolled impervious and semi-pervious earth-fill', 'T');

   if l_host_office_code is not null then
      ----------------------------------------------------------------------
      -- delete any local records that are replaced by the common records --
      ----------------------------------------------------------------------
      for rec in (select * 
                    from at_embank_structure_type
                   where db_office_code = l_cwms_office_code 
                   order by structure_type_code
                 )
      loop
         -------------------------------
         -- get the local record code --
         -------------------------------
         begin
            select structure_type_code
              into l_matching_code
              from at_embank_structure_type
             where structure_type_display_value = rec.structure_type_display_value
               and db_office_code = l_host_office_code;
         exception
            when no_data_found then continue;
         end;   
         ----------------------------------------------------------
         -- update values foreign keyed to the local record code --
         ----------------------------------------------------------
         update at_embankment
            set structure_type_code = rec.structure_type_code
          where structure_type_code = l_matching_code;  
         -----------------------------
         -- delete the local record --
         -----------------------------
         delete
           from at_embank_structure_type
          where structure_type_code = l_matching_code; 
      end loop;
   end if;
end;   
/

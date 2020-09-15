-------------------------------
-- insert the common records --
-------------------------------
insert into at_embank_structure_type values(1, 53, 'Rolled Earth-Filled',      'An embankment formed by compacted earth',                                'T');
insert into at_embank_structure_type values(2, 53, 'Natural',                  'A natural embankment',                                                   'T');
insert into at_embank_structure_type values(3, 53, 'Concrete Arch',            'An embankment formed by concrete arches',                                'T');
insert into at_embank_structure_type values(4, 53, 'Dble-Curv Concrete Arch',  'An embankment formed by thin, double-curvature concrete arches',         'T');
insert into at_embank_structure_type values(5, 53, 'Concrete Apron',           'An embankment formed by a concrete apron',                               'T');
insert into at_embank_structure_type values(6, 53, 'Concrete Dam',             'An embankment formed by concrete',                                       'T');
insert into at_embank_structure_type values(7, 53, 'Concrete Gravity',         'An embankment formed by concrete gravity materials',                     'T');
insert into at_embank_structure_type values(8, 53, 'Rolld Imperv Earth-Fill',  'An embankment formed by rolled impervious and random earth-fill',        'T');
insert into at_embank_structure_type values(9, 53, 'Imprv/Semiperv EarthFill', 'An embankment formed by rolled impervious and semi-pervious earth-fill', 'T');
commit;
declare
   l_matching_code    integer;
begin
   ----------------------------------------------------------------------
   -- delete any local records that are replaced by the common records --
   ----------------------------------------------------------------------
   for rec in (select *
                 from at_embank_structure_type
                where db_office_code = cwms_util.db_office_code_all
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
            and db_office_code != cwms_util.db_office_code_all;
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
end;
/

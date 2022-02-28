create or replace trigger at_vloc_level_constituent_t01
   before insert or update of constituent_abbr, constituent_name, constituent_type
   on at_vloc_lvl_constituent
   for each row
declare
   l_parts str_tab_t;
begin
   if substr(:new.constituent_abbr, 1, 1) != substr(:new.constituent_type,1 , 1) then
      cwms_err.raise('ERROR', 'Constituent abbreviation must start with the same letter as constituent type');
   end if;
   case :new.constituent_type
   when 'LOCATION_LEVEL' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 5 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid location level identifier');
      end if;
   when 'RATING' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 4 or instr(l_parts(2), ';') = 0 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid rating specification');
      end if;
   when 'TIME_SERIES' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 6 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid time series identifier');
      end if;
   when 'FORMULA' then
      begin
         l_parts := cwms_util.tokenize_expression(:new.constituent_name);
      exception
         when others then
            cwms_err.raise('ERROR', 'Constituent name is not a valid formula');
      end;
   else cwms_err.raise('ERROR', 'Constituent type must be one of ''LOCATION_LEVEL'', ''RATING'', ''TIME_SERIES'', or ''FORMULA''');
   end case;
end at_vloc_level_constituent_t01;
/
create or replace trigger at_gate_group_t01
before insert or update on at_gate_group
for each row
declare
   l_category_id         at_loc_category.loc_category_id%type;
   l_shared_loc_alias_id at_loc_group.shared_loc_alias_id%type;
   l_count               pls_integer;
   l_rating_spec         rating_spec_t;
   l_office_code         cwms_office.office_code%type;
   l_office_id           cwms_office.office_id%type;
begin
   select lc.loc_category_id,
          lg.shared_loc_alias_id,
          lg.db_office_code
     into l_category_id,
          l_shared_loc_alias_id,
          l_office_code
     from at_loc_group lg,
          at_loc_category lc
    where lg.loc_group_code = :new.loc_group_code
      and lc.loc_category_code = lg.loc_category_code;

   if upper(l_category_id) != 'RATING' then
      cwms_err.raise('ERROR', 'Location group is not a rating location group');
   elsif l_shared_loc_alias_id is not null then
      select office_id into l_office_id from cwms_office where office_code = l_office_code;
      begin
         l_rating_spec := rating_spec_t(
            l_shared_loc_alias_id,
            l_office_id);
      exception
         when others then cwms_err.raise('ERROR', 'Location group specifies invalid rating specification: '||l_shared_loc_alias_id);
      end;
   end if;

   select count(*)
     into l_count
     from at_loc_group_assignment
    where loc_group_code = :new.loc_group_code
      and location_code not in (select outlet_location_code from at_outlet);

   if l_count > 0 then
      cwms_err.raise('ERROR', 'Location group contains non-outlet locations');
   end if;
end at_gate_group_t01;
/
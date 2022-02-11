create or replace trigger at_loc_group_t01
before insert or update of shared_loc_alias_id on at_loc_group
for each row
declare
   l_rec         at_gate_group%rowtype;
   l_rating_spec rating_spec_t;
   l_office_id   cwms_office.office_id%type;
begin
   select *
     into l_rec
     from at_gate_group
    where loc_group_code = :new.loc_group_code;

   select office_id into l_office_id from cwms_office where office_code = :new.db_office_code;
   begin
      l_rating_spec := rating_spec_t(
         :new.shared_loc_alias_id,
         l_office_id);
   exception
      when others then cwms_err.raise('ERROR', 'Gate location group specifies invalid rating specification: '||:new.shared_loc_alias_id);
   end;
exception
   when no_data_found then null;
end at_loc_group_t01;
/
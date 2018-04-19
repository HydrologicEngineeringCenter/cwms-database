alter table at_virtual_rating drop constraint at_virtual_rating_u1;
alter table at_virtual_rating_element add constraint at_virtual_rating_element_fk2 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code);
alter table at_transitional_rating drop constraint at_transitional_rating_u1;

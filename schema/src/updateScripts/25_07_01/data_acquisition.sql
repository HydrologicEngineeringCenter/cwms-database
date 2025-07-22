insert into at_loc_category (
   loc_category_code,
   loc_category_id,
   db_office_code,
   loc_category_desc
)
   select 10,
          'Data Acquisition',
          53,
          'These Locations Groups are used to manage data acquisition from other organizations'
    from dual
    where not exists (select 1 from at_loc_category where loc_category_code = 10);

insert into at_loc_group (
   loc_group_code,
   loc_category_code,
   loc_group_id,
   loc_group_desc,
   db_office_code,
   shared_loc_alias_id,
   shared_loc_ref_code,
   loc_group_attribute
)
   select 201,
          10,
          'USGS Measurements',
          'These Locations will be used to store Measurement data acquired from the USGS',
          53,
          null,
          null, null
    from dual
    where not exists (select 1 from at_loc_group where loc_group_code = 201 );
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
   select 12,
          1,
          'NOAA Tides and Currents ID',
          'NOAA Tides and Currents Station IDs',
          53,
          null,
          null,
          null
     from dual
    where not exists (
      select 1
        from at_loc_group
       where loc_group_code = 12
   );
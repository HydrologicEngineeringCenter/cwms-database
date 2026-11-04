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
   select 202,
          10,
          'PIXML RFC CHPS Aliases',
          'These Locations will be used to store PIXML RFC CHPS data. Locations not already in NWS Handbook 5 ID',
          53,
          null,
          null,
          null
     from dual
    where not exists (
      select 1
        from at_loc_group
       where loc_group_code = 202
   );

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 206,
               10,
               'PIXML RFC CHPS Acquisition',
               'These TS Id''s will be used to ingest PIXML RFC CHPS forecast data',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 206);
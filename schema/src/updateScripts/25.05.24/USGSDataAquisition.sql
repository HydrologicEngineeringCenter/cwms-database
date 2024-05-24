INSERT INTO AT_TS_CATEGORY (TS_CATEGORY_CODE,
                            TS_CATEGORY_ID,
                            DB_OFFICE_CODE,
                            TS_CATEGORY_DESC)
     SELECT 10,
               'Data Acquisition',
               53,
               'These TS Groups are used to manage data aquisition from other organizations'
    from dual
    where NOT EXISTS (select 1 from AT_TS_CATEGORY where TS_CATEGORY_CODE = 10);

COMMIT;

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 201,
               10,
               'USGS TS Data Acquisition',
               'These TS Id''s will be used to store data acquired from the USGS',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 201);
COMMIT;
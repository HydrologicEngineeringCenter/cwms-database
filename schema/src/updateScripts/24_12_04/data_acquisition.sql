INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 202,
               10,
               'ECCC TS Data Acquisition',
               'These TS Id''s will be used to store data acquired from Environment and Climate Change Canada',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 202);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 203,
               10,
               'SHEF Data Acquisition',
               'These TS Id''s will be used to store SHEF data',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 203);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 204,
               10,
               'NRCS Data Acquisition',
               'These TS Id''s will be used to grab SNOTEL data from the NRCS',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 204);
COMMIT;

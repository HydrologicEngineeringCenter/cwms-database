REM INSERTING into CWMS_20.AT_TS_CATEGORY
Insert into AT_TS_CATEGORY (TS_CATEGORY_CODE,
				    TS_CATEGORY_ID,
                    DB_OFFICE_CODE,
                    TS_CATEGORY_DESC) 
	select 11,
           'SHEF Export',
           53,
           'Category for local groups for exporting SHEF data'
    from dual
    where NOT EXISTS (select 1 from CWMS_20.AT_TS_CATEGORY where TS_CATEGORY_CODE = 11);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     select 300,
               11,
               'TEMP SHEF Export',
               'DO NOT USE.  TEMP SHEF Export group.  Create new group(s) for SHEF EXPORT',
               53,
               NULL,
               NULL
    from dual
    where NOT EXISTS (select 1 from AT_TS_GROUP where TS_GROUP_CODE = 300);

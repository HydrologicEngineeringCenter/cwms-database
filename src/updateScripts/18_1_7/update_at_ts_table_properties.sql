update AT_TS_TABLE_PROPERTIES set start_date=TO_DATE('2022-01-01','YYYY-MM-DD') where table_name='AT_TSV_INF_AND_BEYOND';
commit;
insert into AT_TS_TABLE_PROPERTIES values(TO_DATE('2021-01-01','YYYY-MM-DD'),TO_DATE('2022-01-01','YYYY-MM-DD'),'AT_TSV_2021');
commit;

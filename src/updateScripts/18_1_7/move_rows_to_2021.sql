declare
	l_start date;
	l_end date;
begin
	select start_date,end_date into l_start,l_end from at_ts_table_properties where table_name='AT_TSV_2021';
	insert into at_tsv_2021 (select * from cwms_20.at_tsv_inf_and_beyond where date_time >= l_start and date_time < l_end);
	delete from at_tsv_2021 where date_time >= l_start and date_time < l_end;
	commit;
	dbms_output.put_line('Moved ' || sql%rowcount || ' rows to at_tsv_2021 table from at_tsv_inf_and_beyond');
end;
/

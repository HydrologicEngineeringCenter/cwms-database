CREATE OR REPLACE procedure          cwms_ts_retrieve 
(officeid in varchar2, timeseries_desc in varchar2, units in varchar2, start_time in date, end_time in date, at_tsv_rc in out sys_refcursor, inclusive in number default null)

is

ts_interval     number;


begin

	 select ci.interval into ts_interval 
	 from pd_cwms_ts_id_mview mv, at_cwms_ts_spec ts, cwms_interval ci  
	 where ts.ts_code = mv.ts_code and ci.interval_code = ts.interval_code and mv.CWMS_TS_ID=timeseries_desc;

	 if ts_interval=0 then 
	 
	   if inclusive is not null then 
	   
	     open at_tsv_rc for
		     select ts_code, data_entry_date, date_time, value, unit_id, office_id, changed_id, range_id,  protection_id,  repl_cause_id, 
			    repl_method_id,  test_failed_id,  screened_id, validity_id from 
			 (select ts_code, data_entry_date, date_time, value, unit_id, office_id, changed_id, range_id,  protection_id,  repl_cause_id, 
			    repl_method_id,  test_failed_id,  screened_id, validity_id, 
				lag(date_time, 1) over (order by date_time) lagdate, lead(date_time, 1) over (order by date_time) leaddate
		      from at_tsv_dqu_view v  
	   	      where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.unit_id=units
			 ) 
			where leaddate>=start_time 
			  and lagdate<=end_time;

	   
	   else
	 
	    open at_tsv_rc for
			select * from at_tsv_dqu_view v  
	   	    where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.date_time between start_time and end_time  and v.unit_id=units;
		
		end if;
		
		
		
	else
	
	open at_tsv_rc for
	
		select ts_code, nvl(data_entry_date,sysdate) data_entry_date, jdate_time date_time, value, unit_id, office_id, nvl(changed_id, 'MISSING') changed_id,
		       nvl(range_id, 'MISSING') range_id, nvl(protection_id, 'MISSING') protection_id, nvl(repl_cause_id, 'MISSING') repl_cause_id, 
			   nvl(repl_method_id, 'MISSING') repl_method_id, nvl(test_failed_id, 'MISSING') test_failed_id, nvl(screened_id, 'MISSING') screened_id, 
			   nvl(validity_id, 'MISSING') validity_id
 		from (
		select * from  (
   		  select * from q1cwmspd.at_tsv_dqu_view v
		  where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.date_time between start_time and end_time  and v.unit_id=units) v
		  partition by (v.ts_code, v.office_id, cwms_ts_id, unit_id)
		  right outer join 
		  (select column_value jdate_time from table(cast (q1cwmspd.return_time_pipe(start_time,ts_interval,0,end_time) as q1cwmspd.date_table_type))) t
		   on t.jdate_time = v.date_time
		 );
	
	end if;	 
end;
/


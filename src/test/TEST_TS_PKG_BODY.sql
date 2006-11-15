SET TIME ON
SELECT SYSDATE FROM DUAL;
SET ECHO ON

CREATE OR REPLACE PACKAGE BODY test_ts AS

/*
	procedure retrieve_ts (officeid in varchar2, timeseries_desc in varchar2, 
		units in varchar2, start_time in date, end_time in date, 
		at_tsv_rc out sys_refcursor, inclusive in number default null)
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
			  select * from at_tsv_dqu_view v
			  where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.date_time between start_time and end_time  and v.unit_id=units) v
			  partition by (v.ts_code, v.office_id, cwms_ts_id, unit_id)
			  right outer join 
			  (select column_value jdate_time from table(cast (return_time_pipe(start_time,ts_interval,0,end_time) as date_table_type))) t
			   on t.jdate_time = v.date_time
			 );
		
		end if;	 
	end;
*/

--------------------------------------------------------------------------------

procedure retrieve_ts (officeid in varchar2, timeseries_desc in varchar2, 
	units in varchar2, start_time in date, end_time in date, 
	at_tsv_rc out sys_refcursor, inclusive in number default null)
is
ts_interval     number;
begin
	 dbms_application_info.set_module ( 'Cwms_ts_retrieve','Check Interval'); 
	 select ci.interval into ts_interval 
	 from pd_cwms_ts_id_mview mv, at_cwms_ts_spec ts, cwms_interval ci  
	 where ts.ts_code = mv.ts_code and ci.interval_code = ts.interval_code and mv.CWMS_TS_ID=timeseries_desc;
	 if ts_interval=0 then 
	   if inclusive is not null then 
		   dbms_application_info.set_action ('return regular inclusive ts'); 
	     open at_tsv_rc for
		     select ts_code, data_entry_date, date_time, value, unit_id, office_id, changed_id, range_id,  protection_id,  repl_cause_id, 
			    repl_method_id,  test_failed_id,  screened_id, validity_id, quality_code from 
			 (select ts_code, data_entry_date, date_time, value, unit_id, office_id, changed_id, range_id,  protection_id,  repl_cause_id, 
			    repl_method_id,  test_failed_id,  screened_id, validity_id, quality_code,
				lag(date_time, 1) over (order by date_time) lagdate, lead(date_time, 1) over (order by date_time) leaddate
		      from at_tsv_dqu_view v  
	   	      where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.unit_id=units
			 ) 
			where leaddate>=start_time 
			  and lagdate<=end_time;
   	   else
	    dbms_application_info.set_action ('return  regular  ts'); 
	    open at_tsv_rc for
			select ts_code, data_entry_date, date_time, value, unit_id, office_id, changed_id, range_id,  protection_id,  repl_cause_id, 
			    repl_method_id,  test_failed_id,  screened_id, validity_id, quality_code from at_tsv_dqu_view v  
	   	    where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.date_time between start_time and end_time  and v.unit_id=units;
		
		end if;
		
		
		
	else
	
	  dbms_application_info.set_action ('return  irregular  ts'); 
	
	open at_tsv_rc for
	
		select ts_code, nvl(data_entry_date,sysdate) data_entry_date, jdate_time date_time, value, unit_id, office_id, nvl(changed_id, 'MISSING') changed_id,
		       nvl(range_id, 'MISSING') range_id, nvl(protection_id, 'MISSING') protection_id, nvl(repl_cause_id, 'MISSING') repl_cause_id, 
			   nvl(repl_method_id, 'MISSING') repl_method_id, nvl(test_failed_id, 'MISSING') test_failed_id, nvl(screened_id, 'MISSING') screened_id, 
			   nvl(validity_id, 'MISSING') validity_id, quality_code
 		from (
		select * from  (
   		  select * from at_tsv_dqu_view v
		  where v.office_id = officeid and v.cwms_ts_id = timeseries_desc and v.date_time between start_time and end_time  and v.unit_id=units) v
		  partition by (v.ts_code, v.office_id, cwms_ts_id, unit_id)
		  right outer join 
		  (select column_value jdate_time from table(cast (return_time_pipe(start_time,ts_interval,0,end_time) as date_table_type))) t
		   on t.jdate_time = v.date_time
		 );
	
	end if;	 
	
	 dbms_application_info.set_module(null,null); 
end;


--------------------------------------------------------------------------------	
	
	procedure          cwms_ts_test_out(p_cursor in sys_refcursor, html in number default null)
	
	is
	
	type l_rec_type is table of at_tsv_dqu_view%rowtype index by binary_integer;
	
	l_rec l_rec_type;
	
	begin
	
	
	   loop
		   fetch p_cursor bulk collect into l_rec limit 500;
		   for i in 1 .. l_rec.count
		   loop
			   if html is null then 
				  dbms_output.put_line(l_rec(i).ts_code||', '|| l_rec(i).date_time||', '||l_rec(i).data_entry_date||', '||
									   l_rec(i).value||', '||l_rec(i).office_id||','||l_rec(i).unit_id||', '||l_rec(i).cwms_ts_id||', '||
									   l_rec(i).changed_id);
				else	
				  htp.p(l_rec(i).ts_code||', '|| l_rec(i).date_time||', '||l_rec(i).data_entry_date||', '||', '||
									   l_rec(i).value||', '||l_rec(i).office_id||','||l_rec(i).unit_id||', '||l_rec(i).cwms_ts_id);
			   end if;
			end loop;
			exit when p_cursor%notfound;	
		end loop;
		
		close p_cursor;
	end;
	
	procedure          cwms_ts_test
	
	is
	
	l_cursor 		         sys_refcursor;
	office_id				 varchar2(100);
	st_date				 date;
	e_date				 date;
	ts_id					 varchar2(200);
	ts_code				 number;
	unit_val				 varchar2(20);
	
	begin
	 office_id:='NWDP';
	 ts_id:='BCKO.Stage.Inst.0.0.WNC-RAW';
	 st_date:=to_date('12/20/2003','mm/dd/yyyy');
	 e_date	:=to_date('12/30/2003','mm/dd/yyyy');
	 unit_val:='ft';
	 
		   
	   
	 retrieve_ts(officeid=>office_id, timeseries_desc=>ts_id, units=>unit_val, start_time=>st_date, end_time=>e_date, at_tsv_rc=>l_cursor);
	 
	 cwms_ts_test_out(p_cursor=>l_cursor);
		
	   
	end;
	
/*
procedure store_ts (office_id IN VARCHAR2, timeseries_desc IN VARCHAR2, 
					units IN VARCHAR2, timeseries_data IN test_tsv_array,
					store_rule IN BINARY_INTEGER, override_protection IN BINARY_INTEGER)
  is

		   t1count		  number;
 	 	   t2count     	  number;
		   ucount		  number;
		   storedate	  timestamp(3) default systimestamp;
		   tcode		  number;
		      

  
  begin
  
  select ts_code into tcode from pd_cwms_ts_id_mview m where m.CWMS_TS_ID = timeseries_desc;

  select count(*) into ucount from  at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
  where     s.ts_code=tcode
      and	  s.parameter_code = p.parameter_code
  	  and	  p.unit_code = c.from_unit_code
  	  and 	  c.to_unit_code =u.unit_code
  	  and     u.UNIT_ID=units;
	  
if ucount <> 1 then
   raise_application_error(-20103, 'Requested unit conversion not available', true);
end if;	  


  
  select count(*) into t1count from 
(  
  select t.date_time, ts.INTERVAL_UTC_OFFSET/60, mod((t.date_time - trunc(t.date_time))*1440, ts.INTERVAL_UTC_OFFSET/60) offset_diff 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
  where i.interval_code = ts.interval_code
    and ts.ts_code = tcode
    and i.interval>0
    and ts.INTERVAL_UTC_OFFSET>0
)
where offset_diff>0;

if t1count > 0 then
   raise_application_error(-20101, 'Date-Time value falls outside defined UTC_INTERVAL_OFFSET in regular time series', true);
end if;

select count(*) into t2count from 
(
  select  t.date_time, lead(date_time, 1) over (order by date_time) leaddate, 
         1440*(lead(date_time, 1) over (order by date_time)-t.date_time) diff_interval,  i.interval 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
where i.interval_code = ts.interval_code
  and ts.ts_code = tcode
  and i.interval>0
)
where leaddate is not null
   and mod(diff_interval,interval)<>0;

if t2count > 0 then
   raise_application_error(-20102, 'Invalid interval in regular time series', true);
end if;

 
merge into at_tsv_2002 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		               and  date_time<to_date('01/01/2003','mm/dd/yyyy') ) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

		   
merge into at_tsv_2003 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2003','mm/dd/yyyy') and to_date('01/01/2004','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );
		   
merge into at_tsv_2004 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2004','mm/dd/yyyy') and to_date('01/01/2005','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

merge into at_tsv_2005 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and t.date_time between to_date('01/01/2005','mm/dd/yyyy') and to_date('01/01/2006','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );
end;
*/
--------------------------------------------------------------------------------

--Procedure store_ts (office_id IN VARCHAR2, timeseries_desc IN VARCHAR2, units IN VARCHAR2, timeseries_data IN test_tsv_array)
procedure store_ts (office_id IN VARCHAR2, timeseries_desc IN VARCHAR2, 
					units IN VARCHAR2, timeseries_data IN test_tsv_array,
					store_rule IN BINARY_INTEGER, override_protection IN BINARY_INTEGER)

  is

		   t1count		  number;
 	 	   t2count     	  number;
		   ucount		  number;
		   storedate	  timestamp(3) default systimestamp;
		   tcode		  number;
		      

  
  begin
  
  dbms_application_info.set_module('mtest.store_ts','get tscode from ts_id');
  
  select ts_code into tcode from pd_cwms_ts_id_mview m where m.CWMS_TS_ID = timeseries_desc;

  dbms_application_info.set_action('check for unit conversion factors');
  
  select count(*) into ucount from  at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
  where     s.ts_code=tcode
      and	  s.parameter_code = p.parameter_code
  	  and	  p.unit_code = c.from_unit_code
  	  and 	  c.to_unit_code =u.unit_code
  	  and     u.UNIT_ID=units;
	  
if ucount <> 1 then
   raise_application_error(-20103, 'Requested unit conversion not available', true);
end if;	  

dbms_application_info.set_action('check for interval_utc_office violation if regular ts');
  
  select count(*) into t1count from 
(  
  select t.date_time, ts.INTERVAL_UTC_OFFSET/60, mod((t.date_time - trunc(t.date_time))*1440, ts.INTERVAL_UTC_OFFSET/60) offset_diff 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
  where i.interval_code = ts.interval_code
    and ts.ts_code = tcode
    and i.interval>0
    and ts.INTERVAL_UTC_OFFSET>0
)
where offset_diff>0;

if t1count > 0 then
   raise_application_error(-20101, 'Date-Time value falls outside defined UTC_INTERVAL_OFFSET in regular time series', true);
end if;

dbms_application_info.set_action('check for interval violation if regular ts');


select count(*) into t2count from 
(
  select  t.date_time, lead(date_time, 1) over (order by date_time) leaddate, 
         1440*(lead(date_time, 1) over (order by date_time)-t.date_time) diff_interval,  i.interval 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
where i.interval_code = ts.interval_code
  and ts.ts_code = tcode
  and i.interval>0
)
where leaddate is not null
   and mod(diff_interval,interval)<>0;

if t2count > 0 then
   raise_application_error(-20102, 'Invalid interval in regular time series', true);
end if;

 
dbms_application_info.set_action('merge into <=2002 yearly table ');

 
merge into at_tsv_2002 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		               and  date_time<to_date('01/01/2003','mm/dd/yyyy') ) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

dbms_application_info.set_action('merge into 2003 yearly table ');
		   
merge into at_tsv_2003 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2003','mm/dd/yyyy') and to_date('01/01/2004','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

dbms_application_info.set_action('merge into 2004 yearly table ');   
		   
merge into at_tsv_2004 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2004','mm/dd/yyyy') and to_date('01/01/2005','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

dbms_application_info.set_action('merge into 2005 yearly table ');

		   
merge into at_tsv_2005 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2005','mm/dd/yyyy') and to_date('01/01/2006','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

commit;		   
		   
dbms_application_info.set_module(null, null);
  	   
			
end;
--------------------------------------------------------------------------------

procedure checkstore

is

		   t1count		  number;
 	 	   t2count     	  number;
		   t3count		  number;
		   storedate	  timestamp(3) default systimestamp;
		   tcode		  number;
		   timeseries_data		  test_tsv_array;
		   timeseries_desc				 varchar2(200);
		   units		  varchar2(100); 
		      
begin

select cast(multiset( select test_tsv_type(date_time,100.0, quality_code) from at_tsv_view 
 where ts_code =6032 and date_time between to_date('01/01/2005','mm/dd/yyyy') and to_date('02/01/2005','mm/dd/yyyy')) as test_tsv_array ) into timeseries_data from dual;
	   
select count(*) into t3count from TABLE(cast(timeseries_data as test_tsv_array));

 
 select cwms_ts_id, unit_id into timeseries_desc, units from pd_cwms_ts_id_mview where ts_code=6032;

  
 --units:='1000 m2';
  
  select ts_code into tcode from pd_cwms_ts_id_mview m where m.CWMS_TS_ID = timeseries_desc;
  
  select count(*) into t1count from 
(  
  select t.date_time, ts.INTERVAL_UTC_OFFSET/60, mod((t.date_time - trunc(t.date_time))*1440, ts.INTERVAL_UTC_OFFSET/60) offset_diff 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
  where i.interval_code = ts.interval_code
    and ts.ts_code = tcode
    and i.interval>0
    and ts.INTERVAL_UTC_OFFSET>0
)
where offset_diff>0;

if t1count > 0 then
   raise_application_error(-20101, 'Date-Time value falls outside defined UTC_INTERVAL_OFFSET in regular time series', true);
end if;

select count(*) into t2count from 
(
  select  t.date_time, lead(date_time, 1) over (order by date_time) leaddate, 
         1440*(lead(date_time, 1) over (order by date_time)-t.date_time) diff_interval,  i.interval 
    from TABLE(cast(timeseries_data as test_tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i 
where i.interval_code = ts.interval_code
  and ts.ts_code = tcode
  and i.interval>0
)
where leaddate is not null
   and mod(diff_interval,interval)<>0;

if t2count > 0 then
   raise_application_error(-20102, 'Invalid interval in regular time series', true);
end if;

 

 
merge into at_tsv_2002 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		               and  date_time<to_date('01/01/2003','mm/dd/yyyy') ) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );

		   
merge into at_tsv_2003 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2003','mm/dd/yyyy') and to_date('01/01/2004','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );
		   
merge into at_tsv_2004 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2004','mm/dd/yyyy') and to_date('01/01/2005','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );
		   
dbms_output.put_line(sql%rowcount||' rows affected');		   
		   

merge into at_tsv_2005 t1 
		   using (select  t.date_time, (t.value/c.factor) - c.offset value, t.quality_code from TABLE(cast(timeseries_data as test_tsv_array)) t, 
		                at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p, cwms_unit u
    					where s.ts_code=tcode
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and 	  c.to_unit_code =u.unit_code
  						and u.UNIT_ID=units 
		             and date_time between to_date('01/01/2005','mm/dd/yyyy') and to_date('01/01/2006','mm/dd/yyyy')) t2
		   on ( t1.ts_code = tcode and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value,  t1.data_entry_date = storedate, t1.quality_code = t2.quality_code
		   when not matched then insert(ts_code, date_time, data_entry_date, value, quality_code ) values ( tcode, t2.date_time, storedate, t2.value, t2.quality_code );
	
	commit;   
			
end;	   


END TEST_TS; --end package body
/

SHOW ERRORS
SET ECHO OFF
SET TIME OFF

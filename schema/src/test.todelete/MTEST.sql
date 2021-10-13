SET TIME ON
SELECT SYSDATE FROM DUAL;
SET ECHO ON

DROP PACKAGE cwms.mtest;
DROP TYPE cwms.at_ts_table_array;
DROP TYPE cwms.at_ts_table_type;

CREATE OR REPLACE TYPE cwms.at_ts_table_type AS OBJECT (ts_code NUMBER, date_time DATE, data_entry_date DATE, value NUMBER, quality RAW(4));
/
CREATE OR REPLACE TYPE cwms.at_ts_table_array IS TABLE OF at_ts_table_type;
/
CREATE OR REPLACE PACKAGE cwms.mtest AS
	PROCEDURE mergetest (l_data IN at_ts_table_array );
	PROCEDURE mtest_demo(office IN VARCHAR2, utc_offset IN NUMBER, timeseries_desc IN VARCHAR2);
--	PROCEDURE mtest_demo;
END;
/
CREATE OR REPLACE PACKAGE BODY cwms.mtest AS
	PROCEDURE mergetest (l_data IN at_ts_table_array ) IS
	 --l_data mergeArrayType;
	 starttime        timestamp(6);
	 endtime      timestamp(6);
	 dur            interval day to second(6);
	 t2count     number;
	   begin
		--starttime:=systimestamp;
	--        select cast(
	--             multiset( select mergetype(ts_code,date_time,value) from mt2 ) as mergeArrayType )
	--          into l_data
	--          from dual;
		   merge into at_time_series_value t1
		   using ( select t.ts_code, t.date_time, t.value, t.quality, t.data_entry_date from TABLE(cast(l_data as at_ts_table_array)) t) t2
		   on ( t1.ts_code = t2.ts_code and t1.date_time = t2.date_time )
		   when matched then update set t1.value = t2.value, t1.quality = t2.quality, t1.data_entry_date = t2.data_entry_date
		   when not matched then insert (ts_code, date_time, data_entry_date, value, quality) values ( t2.ts_code, t2.date_time, t2.data_entry_date, t2.value, t2.quality );
		--select count(*) into t2count from table(cast(l_data as at_ts_table_array));
		--endtime:=systimestamp;
		--dur:= endtime - starttime;
		--insert into mtest_log  (start_time, end_time, duration, record_cnt) values  (starttime, endtime, dur, t2count);
		--dbms_output.put_line('Runtime = '||to_char(endtime-starttime, 'mi:ss'));
		--dbms_output.put_line('Records processed = '||to_char((t2count-t1count)));
		commit;
	   end;
	   
--runTest(String office, int utcIntervalOffset, String desc)	   
--	   PROCEDURE mtest_demo
--	   AS LANGUAGE JAVA
--	   NAME 'mergetest.MergeTest.runTest()';

	   PROCEDURE mtest_demo(office IN VARCHAR2, utc_offset IN NUMBER, timeseries_desc IN VARCHAR2)
	   AS LANGUAGE JAVA
	   NAME 'mergetest.MergeTest.runTest(java.lang.String, int, java.lang.String)';

END MTEST;
/

SHOW ERRORS
SET ECHO OFF
SET TIME OFF

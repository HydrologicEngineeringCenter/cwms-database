CREATE OR REPLACE PACKAGE BODY mrr AS
/******************************************************************************
   NAME:       mrr
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/26/2005             1. Created this package body.
******************************************************************************/

/****************************************/
-- Select values and return a ref cursor
  PROCEDURE Select_Values_ref (
    cwms_tsid  IN VARCHAR2,
    start_date IN DATE,
	start_flag IN INTEGER,
	end_date   IN DATE,
	end_flag   IN INTEGER,
	units	   IN VARCHAR2,
    vals       OUT SYS_REFCURSOR,
    err_num    OUT INTEGER) IS
    tssid        INTEGER;
    v_start_date date;
    v_end_date   date;
    sql_string   VARCHAR2(600);
	sql_string2	 VARCHAR2(250);
    strt_yr      NUMBER(4);
    end_yr       NUMBER(4);
	err_num2	 integer;
  BEGIN
    --initialize variables
    err_num := 0;
    err_num2 := 0;
	
	-- Get the ts_code
	select ts_code into tssid from cwms2.at_cwms_ts_id_mview
	  where cwms_ts_id = cwms_tsid; 
	--dbms_output.put_line ('TS_CODE= '||tssid);
	
    -- Calculate start and end years for previous/next values.
    strt_yr := to_char(start_date,'YYYY');
    end_yr := to_char(end_date,'YYYY');
	--dbms_output.put_line ('start year = '|| strt_yr || ' end year = '|| end_yr);

	-- Get start and end date if previous/next values needed.
    if (start_flag = 1) then
	  begin
        -- Get the inline view string for the yearly table union.
	    build_inline_string (strt_yr-1, strt_yr, sql_string2, err_num2);
	    sql_string := 'select nvl(max(date_time),:start_date) from (' 
	      || sql_string2 
	      || ') where ts_code = :tssid'
	      || ' and date_time < :start_date'
		  || ' and date_time >= :start_date - 365';
		  execute immediate sql_string into v_start_date using start_date, tssid, start_date, start_date; 
		--dbms_output.put_line ('Old start date= ' || to_char(start_date,'HH24:MI DD-MON-YYYY'));
		--dbms_output.put_line ('New start date= ' || to_char(v_start_date,'HH24:MI DD-MON-YYYY'));
	  exception
	    when others then
		  -- have to somehow inform the calling routine of problem.
		  dbms_output.put_line ('v_start_date error= ' || sqlerrm);
		  v_start_date := start_date;
	  end;
	else
	  v_start_date := start_date;
	end if;
    if (end_flag = 1) then
	  begin
        -- Get the inline view string for the yearly table union.
	    build_inline_string (end_yr, end_yr+1, sql_string2, err_num2);
	    sql_string := 'select nvl(min(date_time),:end_date) from (' 
	      || sql_string2 
	      || ') where ts_code = :tssid'
	      || ' and date_time > :end_date'
		  || ' and date_time <= :end_date + 365';
		  execute immediate sql_string into v_end_date using end_date, tssid, end_date, end_date; 
		--dbms_output.put_line ('Old end date= ' || to_char(end_date,'HH24:MI DD-MON-YYYY'));
		--dbms_output.put_line ('New end date= ' || to_char(v_end_date,'HH24:MI DD-MON-YYYY'));
	  exception
	    when others then
		  -- have to somehow inform the calling routine of problem.
		  dbms_output.put_line ('v_end_date error= ' || sqlerrm);
		  v_end_date := end_date;
	  end;
	else
	  v_end_date := end_date;
	end if;
	
    -- Calculate start and end years to retrieve all values.
    strt_yr := to_char(v_start_date,'YYYY');
    end_yr := to_char(v_end_date,'YYYY');
	--dbms_output.put_line ('start year = '|| strt_yr || ' end year = '|| end_yr);

    -- Get the inline view string for the yearly table union.
	build_inline_string (strt_yr, end_yr, sql_string2, err_num2);
	
	--dbms_output.put_line ('SQLstr = ' || sql_string2);
		  
    sql_string := 'SELECT t.date_time, t.value/c.factor - c.offset value, t.quality_code FROM ( '
      || sql_string2 || ' ) t, at_cwms_ts_spec s, '
	  || ' cwms_unit_conversion c,'
	  || ' cwms_parameter p,'
	  || ' cwms_unit u'
	  || ' where s.parameter_code = p.parameter_code'
	  || ' and p.unit_code = c.from_unit_code'
	  || ' and c.to_unit_code = u.unit_code'
	  || ' and upper(u.unit_id) = upper(:units)'
	  || ' and t.ts_code = :tssid'
	  || ' and s.ts_code = :tssid'
	  || ' and t.date_time BETWEEN :beg_date AND :end_date'
	  || ' ORDER BY date_time, data_entry_date';

	--dbms_output.put_line ('sql= '||substr(sql_string,1,250));
	--dbms_output.put_line ('sql= '||substr(sql_string,251,250));
	--dbms_output.put_line ('sql= '||substr(sql_string,501,250));
	--dbms_output.put_line ('start date = '|| v_start_date || ' end date = '|| v_end_date);
	--dbms_output.put_line ('units = '|| units || ' tssid = '|| tssid);
	
    -- Open the cursor.
	open vals for sql_string using units, tssid, tssid, v_start_date, v_end_date;
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line (tssid || ' ' || SQLERRM);
      err_num := SQLCODE;
  END select_values_ref;
/****************************************/
 PROCEDURE build_inline_string (
    start_year    IN integer,
    end_year      IN integer,
	inline_string OUT varchar2,
    err_num       OUT INTEGER) IS
	i           integer;
	v_curr_year number(4);

 BEGIN	
    select to_char(sysdate,'YYYY') into v_curr_year from dual;
	--dbms_output.put_line('Current year = ' || v_curr_year);
    -- Loop through the years to build the string to union the yearly tables.
	i :=0;
    for iter in start_year..end_year LOOP
	  -- Make sure we don't go past the current year.
	  if (iter <= v_curr_year) then
	    if (iter < 2002) THEN
	      if i = 0 THEN 
            inline_string := ' SELECT * FROM cwms2.AT_TIME_SERIES_VALUE where ts_code = :tss_id';
		    i := i +1;
		  else
		    i := i +1;
		  end if;
	    else
	      if i > 0 THEN
	        inline_string := inline_string || ' union all SELECT * FROM cwms2.AT_TSV_' || iter;
			--dbms_output.put_line('Inline = ' || inline_string);
		    i := i +1;
		  else
		    inline_string := ' SELECT * FROM cwms2.AT_TSV_' || iter;
			--dbms_output.put_line('Inline = ' || inline_string);
		    i := i +1;
		  end if;
	    end if;
	  end if;
	END LOOP;
 END build_inline_string;
/****************************************/
--Insert time series values.
  PROCEDURE insert_values_dyn (
    officeid    IN VARCHAR2,
    cwms_tsids  IN  Char200ArrayTyp,
	units		IN	OUT VARCHAR2,
    ora_dates   IN  DateArrayTyp,
    vals        IN  BDArrayTyp,
	qual_codes  IN  NumArrayTypIB,
    num_vals    IN  INTEGER,
    err_num     OUT INTEGER) IS
    sql_string  VARCHAR2(200);
    error_text  VARCHAR2(150);
    tssid       INTEGER;
	factor		binary_double;
	offset		binary_double;
	last_cwms_tsid varchar2(200);
  BEGIN
    err_num := 0;
	last_cwms_tsid := 'x';
    --do for the number of values
    FOR i IN 1..num_vals LOOP
	  -- Get the ts_code if different station.
	  begin
	    if (cwms_tsids(i) <> last_cwms_tsid) then
	      select ts_code into tssid from CWMS2.at_cwms_ts_id_mview
	        where cwms_ts_id = cwms_tsids(i); 
	      --dbms_output.put_line ('TS_CODE= '||tssid);
	    end if;
	    if units is null then 
	      select unit_id into units from at_cwms_ts_id_mview 
  	      where cwms_ts_id=cwms_tsids(i);
        end if;
	  exception
	    when others then
		  tssid := 0;
	  end;
	  -- Find conversion factor and offset for the
	  begin 
	    select c.factor into factor from at_cwms_ts_spec s, cwms_unit_conversion c, 
	    cwms_parameter p, cwms_unit u
	    where s.ts_code=tssid
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and   c.to_unit_code =u.unit_code
  						and   upper(u.UNIT_ID)=upper(units);
		select c.offset into offset	from at_cwms_ts_spec s, cwms_unit_conversion c, 
	    cwms_parameter p, cwms_unit u
	    where s.ts_code=tssid
  						and	  s.parameter_code = p.parameter_code
  						and	  p.unit_code = c.from_unit_code
  						and   c.to_unit_code =u.unit_code
  						and   upper(u.UNIT_ID)=upper(units);
	  exception
	    when others then
		  tssid := 0;
	  	  err_num := SQLCODE;									
	  end;

	  dbms_output.put_line ('I '||factor||' '||offset);
	  if (tssid > 0) then
        BEGIN
  	    last_cwms_tsid := cwms_tsids(i);
          --build the sql string
          IF (SUBSTR(TO_CHAR(ora_dates(i),'YYYY'),1,4) < 2002) THEN
              sql_string := 'INSERT INTO AT_TIME_SERIES_VALUE';
            ELSE
              sql_string := 'INSERT INTO AT_TSV_' || SUBSTR(TO_CHAR(ora_dates(i),'YYYY'),1,4);
          END IF;
          sql_string := sql_string || ' (data_entry_date, date_time, value, ts_code, quality_code) ';
          sql_string := sql_string || 'VALUES (SYSDATE, :dte_tme, ( :val /to_number('|| factor ||')- to_number('|| offset ||')), :tssid, :qual_code)';
          EXECUTE IMMEDIATE sql_string
            USING ora_dates(i), vals(i), tssid, qual_codes(i);
            --dbms_output.put_line ('I '||ora_dates(i)||' '||vals(i)||' '||tss_ids(i));
  	    --dbms_output.put_line ('Inserted');
        EXCEPTION
  	    WHEN DUP_VAL_ON_INDEX THEN
  	      dbms_output.put_line ('Duplicate');
  	      BEGIN
              IF (TO_CHAR(ora_dates(i),'YYYY') < 2002) THEN
                  sql_string := 'UPDATE AT_TIME_SERIES_VALUE';
                ELSE
                  sql_string := 'UPDATE AT_TSV_' || TO_CHAR(ora_dates(i),'YYYY');
              END IF;
              sql_string := sql_string || ' set data_entry_date = sysdate, value = :val /to_number('|| factor ||')- to_number('|| offset ||')' ;
              sql_string := sql_string || ' where ts_code = :tssid and date_time = :dte_tme';
              EXECUTE IMMEDIATE sql_string
                USING vals(i), tssid, ora_dates(i);
  	        dbms_output.put_line ('Updated ' || tssid ||' '||vals(i)||' '||ora_dates(i));
  		  EXCEPTION
  		    WHEN OTHERS THEN
                error_text := SUBSTR(SQLERRM,1,150);
  		      dbms_output.put_line ('Error with update- ' || error_text);
                dbms_output.put_line (sql_string);
                err_num := SQLCODE;
  		  END;
          WHEN OTHERS THEN
            error_text := SUBSTR(SQLERRM,1,150);
            dbms_output.put_line ('NI '||ora_dates(i)||' '||vals(i)||' '||tssid);
            dbms_output.put_line ('IVT Error = '||error_text);
            dbms_output.put_line (sql_string);
            err_num := SQLCODE;
    	      dbms_output.put_line ('Value not inserted');
        END;
	  END IF;
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      err_num := SQLCODE;
  END insert_values_dyn;
/*************************************/
-- Select values and return a plsql table
  PROCEDURE Select_Values_pls (
    officeid   IN VARCHAR2,
    cwms_tsid  IN VARCHAR2,
    start_date IN DATE,
	start_flag IN INTEGER,
	end_date   IN DATE,
	end_flag   IN INTEGER,
	units	   IN OUT VARCHAR2,
    vals       OUT SYS_REFCURSOR,
	num_vals   OUT INTEGER,
    err_num    OUT INTEGER) IS
    tssid        INTEGER;
    v_chk_sd     date;
    v_chk_ed     date;
    v_start_date date;
    v_end_date   date;
    sql_string   VARCHAR2(600);
    strt_yr      NUMBER(4);
    end_yr       NUMBER(4);
    curr_yr      NUMBER(4);
    val          REAL;
    date_time    DATE;
	year		 NUMBER;
    i            INTEGER;
	v_data		 mrrTable := mrrTable();
	dte			 TIMESTAMP(6);
	val2		 BINARY_DOUBLE;
	qual		 NUMBER;
	prev_date_time DATE;
	type TsValCursor is REF CURSOR;
	val_cv TsValCursor;
  BEGIN
    --initialize variables
    err_num := 0;
    i := 0;
	
	-- Get the ts_code
	select ts_code into tssid from CWMS2.at_cwms_ts_id_mview
	  where cwms_ts_id = cwms_tsid; 
	dbms_output.put_line ('TS_CODE= '||tssid);
	
	if units is null then 
	  select unit_id into units from at_cwms_ts_id_mview 
  	  where cwms_ts_id=cwms_tsid;
     end if;
	
	-- **************** Adjust start and end date if previous/next values needed.************
    if (start_flag = 1) then
      strt_yr := TO_CHAR(start_date,'YYYY');
	  begin
        sql_string := 'SELECT max(date_time) ' ;
        IF (strt_yr < 2002) THEN
          sql_string := sql_string || ' FROM AT_TIME_SERIES_VALUE';
        ELSE
          sql_string := sql_string || ' FROM AT_TSV_' || strt_yr;
        END IF;
        sql_string := sql_string || ' where ts_code = :tssid and date_time < :start_date and date_time >= :start_date - 365';
        --dbms_output.put_line (sql_string);
        execute immediate sql_string into v_chk_sd using tssid, start_date, start_date;
		--dbms_output.put_line ('Old/New start date = ' || to_char(start_date,'MIHH24DDMMYYYY') ||' - '|| to_char(v_chk_sd,'MIHH24DDMMYYYY'));
        if (v_chk_sd is null) then
	      -- Didn't find a value. Check the previous year's table if we didn't check at_time_series_value.
	      if (strt_yr < 2002) then
		    -- We've already checked back as far as we can.
		    v_chk_sd := start_date;
		  else
		    -- Move year back one.
		    strt_yr := strt_yr - 1;
		    -- We can keep the string, just need to change the table name.
	        if (strt_yr < 2002) then
		      sql_string := replace(sql_string,'AT_TSV_2002','AT_TIME_SERIES_VALUE');
		    else
		      sql_string := replace(sql_string,strt_yr+1,strt_yr);
		    end if;
            --dbms_output.put_line (sql_string);
            execute immediate sql_string into v_chk_sd using tssid, start_date, start_date;
			-- If we didn't find a previous start date, set it to the initial start date.
			if (v_chk_sd is null) then
			  v_chk_sd := start_date;
			end if;
		    --dbms_output.put_line ('Old/New start date = ' || to_char(start_date,'MIHH24DDMMYYYY') ||' - '|| to_char(v_chk_sd,'MIHH24DDMMYYYY'));
          end if;
		end if;
	  exception
	    when others then
		  -- have to somehow inform the calling routine of problem.
		  dbms_output.put_line ('v_start_date error= ' || sqlerrm);
		  v_chk_sd := start_date;
	  end;
	else
	  v_chk_sd := start_date;
	end if;
   if (end_flag = 1) then
      end_yr := TO_CHAR(end_date,'YYYY');
	  begin
        sql_string := 'SELECT min(date_time) ' ;
        IF (end_yr < 2002) THEN
          sql_string := sql_string || ' FROM AT_TIME_SERIES_VALUE';
        ELSE
          sql_string := sql_string || ' FROM AT_TSV_' || end_yr;
        END IF;
        sql_string := sql_string || ' where ts_code = :tssid and date_time > :end_date and date_time <= :end_date + 365';
        --dbms_output.put_line (sql_string);
        execute immediate sql_string into v_chk_ed using tssid, end_date, end_date;
		--dbms_output.put_line ('Old/New end date = ' || to_char(end_date,'MIHH24DDMMYYYY') ||' - '|| to_char(v_chk_ed,'MIHH24DDMMYYYY'));
        if (v_chk_ed is null) then
	      -- Didn't find a value. Check the next year's table if we won't check at_time_series_value again or we are at last yearly table.
		  select to_char(sysdate,'YYYY') into curr_yr from dual;
	      if (end_yr = curr_yr) then
		    -- We've already checked as far forward as we can.
		    v_chk_ed := end_date;
	      elsif (end_yr <= 2000) then
		    -- Next check will still be in at_time_series_values, so don't check.
		    v_chk_ed := end_date;
		  else
		    -- Move ahead one year.
		    end_yr := end_yr + 1;
		    -- We can keep the string, just need to change the table name.
	        if (end_yr = 2002) then
			  -- Last check was 2001, so at_time_series_value table used
		      sql_string := replace(sql_string,'AT_TIME_SERIES_VALUE','AT_TSV_2002');
		    else
		      sql_string := replace(sql_string,end_yr-1,end_yr);
		    end if;
            --dbms_output.put_line (sql_string);
            execute immediate sql_string into v_chk_ed using tssid, end_date, end_date;
			-- If we didn't find a new end date, set it to the initial end date.
			if (v_chk_ed is null) then
			  v_chk_ed := end_date;
			end if;
		    --dbms_output.put_line ('Old/New end date = ' || to_char(end_date,'MIHH24DDMMYYYY') ||' - '|| to_char(v_chk_ed,'MIHH24DDMMYYYY'));
          end if;
		end if;
	  exception
	    when others then
		  -- have to somehow inform the calling routine of problem.
		  dbms_output.put_line ('v_end_date error= ' || sqlerrm);
          v_chk_ed := end_date;
	  end;
	else
	  v_chk_ed := end_date;
	end if;
	
    -- ***************** Now get the values between start_date and end_date *********************
    strt_yr := TO_CHAR(v_chk_sd,'YYYY');
    end_yr := TO_CHAR(v_chk_ed,'YYYY');
	--DBMS_OUTPUT.PUT_LINE ('start year = '|| strt_yr || ' end year = '|| end_yr);

    -- Since values are stored in yearly tables, we must loop
    -- through the dates to find all values in a particular table.
    for iter in strt_yr..end_yr LOOP
	  --DBMS_OUTPUT.PUT_LINE ('iter = '|| iter);
	  if (v_chk_sd > TO_DATE('00000101' || iter,'MIHH24DDMMYYYY')) then
	    v_start_date := v_chk_sd;
	  else
	    v_start_date := TO_DATE('00000101' || iter,'MIHH24DDMMYYYY');
	  end if;
	  if (v_chk_ed < TO_DATE('59233112' || iter,'MIHH24DDMMYYYY')) then
	    v_end_date := v_chk_ed;
	  else
	    v_end_date := TO_DATE('59233112' || iter,'MIHH24DDMMYYYY');
	  end if;
      -- build sql string
	  --DBMS_OUTPUT.PUT_LINE ('year = '||TO_CHAR(ora_dates(end_num),'YYYY'));
      sql_string := 'SELECT t.date_time, t.data_entry_date, t.value*c.factor - c.offset value, t.quality_code' ;
      IF (TO_CHAR(v_start_date,'YYYY') < 2002) THEN
        sql_string := sql_string || ' FROM AT_TIME_SERIES_VALUE t,';
      ELSE
        sql_string := sql_string || ' FROM AT_TSV_' || TO_CHAR(v_start_date,'YYYY') || ' t,' ;
      END IF;
      sql_string := sql_string || ' at_cwms_ts_spec s, cwms_unit_conversion c, cwms_parameter p,'
        || ' cwms_unit u'
        || ' where s.parameter_code = p.parameter_code'
	    || ' and p.unit_code = c.from_unit_code'
	    || ' and c.to_unit_code = u.unit_code'
	    || ' and upper(u.unit_id) = upper(:units)'
	    || ' and t.ts_code = :tssid'
	    || ' and s.ts_code = :tssid'
	    || ' and t.date_time BETWEEN :beg_date AND :end_date'
	    || ' ORDER BY date_time, data_entry_date';
		
	  --dbms_output.put_line ('sql= '||substr(sql_string,1,250));
	  --dbms_output.put_line ('sql= '||substr(sql_string,251,250));
	  --dbms_output.put_line ('sql= '||substr(sql_string,501,250));
	  --dbms_output.put_line ('start date = '|| v_start_date || ' end date = '|| v_end_date);
	  --dbms_output.put_line ('units = '|| units || ' tssid = '|| tssid);
      --loop through cursor
      open val_cv for sql_string using units, tssid, tssid, v_start_date, v_end_date;

	  prev_date_time := to_date('01-JAN-1800','DD-MON-YYYY');	  
	  LOOP
	    fetch val_cv into date_time, dte, val2, qual;
	    exit when val_cv%notfound;
        IF date_time <> prev_date_time THEN
		  -- New value, increment counter.
          i := i + 1;
          -- Otherwise we have multiple values for the same date_time. 
		  -- Don't increment so we write over previous value;
		END IF;
		v_data.extend;
		v_data(i) := mrrScalarType(date_time, dte, val2, qual);
		prev_date_time := date_time;
      END LOOP;
  
	END LOOP;
	
    num_vals := i;

	--More New code to move from sql type table object to ref cursor
	open vals for 
	select * from TABLE (cast(v_data as mrrTable));

  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line (tssid || ' ' || SQLERRM);
      err_num := SQLCODE;
  END select_values_pls;
/****************************************/
END mrr;
/

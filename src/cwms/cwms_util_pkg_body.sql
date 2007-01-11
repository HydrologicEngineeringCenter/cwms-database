/* Formatted on 2006/12/11 09:09 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_util
AS
/******************************************************************************
*   Name:       CWMS_UTL
*   Purpose:    Miscellaneous CWMS Procedures
*
*   Revisions:
*   Ver        Date        Author      Descriptio
*   ---------  ----------  ----------  ----------------------------------------
*   1.1        9/07/2005   Portin      create_view: at_ts_table_properties start and end dates
*                                      changed to DATE datatype
*   1.0        8/29/2005   Portin      Original
******************************************************************************/--
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_min_dms   NUMBER;
   BEGIN
      l_sec_dms :=
         ROUND (  (  (  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees))
                      * 60.0
                     )
                   - TRUNC (  ABS (  p_decimal_degrees
                                   - TRUNC (p_decimal_degrees)
                                  )
                            * 60
                           )
                  )
                * 60.0,
                2
               );
      l_min_dms :=
               TRUNC (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);

      IF l_sec_dms = 60
      THEN
         RETURN l_min_dms + 1;
      ELSE
         RETURN l_min_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dms;

--
   FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
   BEGIN
      l_sec_dms :=
         ROUND (  (  (  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees))
                      * 60.0
                     )
                   - min_dms (p_decimal_degrees)
                  )
                * 60.0,
                2
               );

      IF l_sec_dms = 60
      THEN
         RETURN 0;
      ELSE
         RETURN l_sec_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END sec_dms;

--
   FUNCTION min_dm (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
   BEGIN
      RETURN ROUND ((ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60
                    ),
                    2
                   );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dm;

   --
   -- return the p_in_date which is in p_in_tz as a date in UTC
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN FROM_TZ (CAST (p_in_date AS TIMESTAMP), p_in_tz) AT TIME ZONE 'GMT';
   END;

   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_num          NUMBER := INSTR (p_full_id, '-', 1, 1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id, '.', 1, 1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.RAISE ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN p_full_id;
      ELSE
         RETURN SUBSTR (p_full_id, 1, l_num - 1);
      END IF;
   END;

   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_num          NUMBER := INSTR (p_full_id, '-', 1, 1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id, '.', 1, 1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.RAISE ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN NULL;
      ELSE
         RETURN SUBSTR (p_full_id, l_num + 1, l_sub_length);
      END IF;
   END;

   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF UPPER (p_true_false) = 'T' OR UPPER (p_true_false) = 'TRUE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   --
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF UPPER (p_true_false) = 'F' OR UPPER (p_true_false) = 'FALSE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

      -- Retruns TRUE if p_true_false is T or True
   -- Returns FALSE if p_true_false is F or False.
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN TRUE;
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN FALSE;
      ELSE
         cwms_err.RAISE ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END;

   
--------------------------------------------------------------------------------
-- function get_real_name
--
   FUNCTION get_real_name (
      p_synonym   IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_name varchar2(32) := upper(p_synonym);
      invalid_sql_name exception;
      pragma exception_init(invalid_sql_name, -44003);
   BEGIN
      begin
         select dbms_assert.simple_sql_name(l_name)
           into l_name
           from dual;
           
         select table_name
           into l_name 
           from sys.all_synonyms 
          where synonym_name = l_name
            and owner = 'PUBLIC' 
            and table_owner = 'CWMS_20';
      exception
         when invalid_sql_name then
            cwms_err.raise('INVALID_ITEM', p_synonym, 'materialized view name');
            
         when no_data_found then null;
      end;
            
      return l_name;
         
   END get_real_name;

--------------------------------------------------------------------------------
-- function pause_mv_refresh
--
   FUNCTION pause_mv_refresh(
      p_mview_name IN VARCHAR2,
      p_reason     IN VARCHAR2 DEFAULT NULL)
      RETURN UROWID
   IS                               
      l_mview_name varchar2(32);
      l_user_id    varchar2(32);
      l_rowid      urowid := null;
      l_tstamp     timestamp;
   BEGIN
      savepoint pause_mv_refresh_start;
       
      l_user_id    := sys_context('userenv', 'session_user');
      l_tstamp     := systimestamp;
      l_mview_name := get_real_name(p_mview_name);
      
      lock table at_mview_refresh_paused in exclusive mode;

      insert
        into at_mview_refresh_paused
      values (l_tstamp, l_mview_name, l_user_id, p_reason)
   returning rowid,
             paused_at
        into l_rowid,
             l_tstamp;
      
      execute immediate 'alter materialized view '
         || l_mview_name
         || ' refresh on demand';
      
      commit;
      
      dbms_output.put_line('MVIEW '''
           || l_mview_name
           || ''' on-commit refresh paused at '
           || l_tstamp
           || ' by '
           || l_user_id
           || ', reason: '
           || p_reason);  

      
      return l_rowid;
      
   exception
      when others then
         rollback to pause_mv_refresh_start;
         raise;
         
   END pause_mv_refresh;

--------------------------------------------------------------------------------
-- procedure resume_mv_refresh
--
   PROCEDURE resume_mv_refresh(p_paused_handle IN UROWID)
   IS
      l_mview_name varchar2(30);
      l_count      binary_integer;
      l_user_id    varchar2(30);
   BEGIN
      l_user_id := sys_context('userenv', 'session_user');
      savepoint resume_mv_refresh_start;
       
      lock table at_mview_refresh_paused in exclusive mode;
      
      select mview_name 
        into l_mview_name 
        from at_mview_refresh_paused
       where rowid = p_paused_handle;
       
      
      delete
        from at_mview_refresh_paused
       where rowid = p_paused_handle;

      select count(*)
        into l_count
        from at_mview_refresh_paused
       where mview_name = l_mview_name;     
       
      if l_count = 0 then
         dbms_mview.refresh(l_mview_name, 'c');
         execute immediate 'alter materialized view '
            || l_mview_name
            || ' refresh on commit';

         dbms_output.put_line('MVIEW '''
              || l_mview_name
              || ''' on-commit refresh resumed at '
              || systimestamp
              || ' by '
              || l_user_id);  
      else
         dbms_output.put_line('MVIEW '''
              || l_mview_name
              || ''' on-commit refresh not resumed at '
              || systimestamp
              || ' by '
              || l_user_id
              || ', paused by '
              || l_count
              || ' other process(es)');  
      end if;
      
      commit;

   EXCEPTION
      when no_data_found then 
         commit;

      when others then
         rollback to resume_mv_refresh_start;
         raise; 
      
   END resume_mv_refresh;
   
--------------------------------------------------------------------------------
-- procedure timeout_mv_refresh_paused
--
   PROCEDURE timeout_mv_refresh_paused
   IS
      TYPE ts_by_mv_t 
         IS TABLE OF at_mview_refresh_paused.paused_at%TYPE 
         INDEX BY at_mview_refresh_paused.mview_name%TYPE;
      l_abandonded_pauses ts_by_mv_t;
      l_mview_name at_mview_refresh_paused.mview_name%TYPE;
      l_now timestamp := systimestamp;
   BEGIN
      savepoint timeout_mv_rfrsh_paused_start;

      lock table at_mview_refresh_paused in exclusive mode;
      
      for rec in (select * from at_mview_refresh_paused) loop
         if l_now - rec.paused_at > mv_pause_timeout_interval then
            if l_abandonded_pauses.exists(rec.mview_name) then
               if rec.paused_at > l_abandonded_pauses(rec.mview_name) then
                  l_abandonded_pauses(rec.mview_name) := rec.paused_at;
               end if;
            else
               l_abandonded_pauses(rec.mview_name) := rec.paused_at;
            end if;
         end if;
      end loop;
            
      l_mview_name := l_abandonded_pauses.first;
      begin
         loop
            exit when l_mview_name is null;
            dbms_mview.refresh(l_mview_name, 'c');
            execute immediate 'alter materialized view '
               || l_mview_name
               || ' refresh on commit';
               
            dbms_output.put_line('MVIEW '''
                 || l_mview_name
                 || ''' ABANDONDED on-commit refresh resumed at '
                 || systimestamp);  
            delete
              from at_mview_refresh_paused
             where mview_name = l_mview_name
               and paused_at <= l_abandonded_pauses(l_mview_name);
            
            l_mview_name := l_abandonded_pauses.next(l_mview_name);
         end loop;
      end;

      commit;

   EXCEPTION
      WHEN no_data_found THEN
         commit;

      WHEN OTHERS THEN
         rollback to timeout_mv_rfrsh_paused_start;
         raise;
      
   END timeout_mv_refresh_paused;
   

--------------------------------------------------------------------------------
-- procedure start_timeout_mv_refresh_job
--
   PROCEDURE start_timeout_mv_refresh_job
   IS
      l_count   binary_integer;
      l_user_id varchar2(30);
      l_job_id  varchar2(30) := 'TIMEOUT_MV_REFRESH_JOB';
      
      function job_count return binary_integer
      is
      begin
         select count(*) into l_count from sys.dba_scheduler_jobs where job_name = l_job_id and owner = l_user_id;
         return l_count;
      end;
   BEGIN
      --------------------------------------
      -- make sure we're the correct user --
      --------------------------------------
      l_user_id := sys_context('userenv', 'session_user');
      if l_user_id != 'CWMS_20' then
         raise_application_error(-20999, 'Must be CWMS_20 user to start job ' || l_job_id, true);
      end if;
      -------------------------------------------
      -- drop the job if it is already running --
      -------------------------------------------
      if job_count > 0 then
         dbms_output.put('Dropping existing job ' || l_job_id || '...');
         dbms_scheduler.drop_job(l_job_id);
         --------------------------------
         -- verify that it was dropped --
         --------------------------------
         if job_count = 0 then
            dbms_output.put_line('done.');
         else
            dbms_output.put_line('failed.');
         end if;
      end if;
      if job_count = 0 then
         begin
            ---------------------
            -- restart the job --
            ---------------------
            dbms_scheduler.create_job(
               job_name        => l_job_id,
               job_type        => 'stored_procedure',
               job_action      => 'cwms_util.timeout_mv_refresh_paused',
               start_date      => null,
               repeat_interval => 'freq=minutely; interval='||mv_pause_job_run_interval,
               end_date        => null,
               job_class       => 'default_job_class',
               enabled         => true,
               auto_drop       => false,
               comments        => 'Times out abandoned pauses to on-commit refreshes on mviews.');

            if job_count = 1 then
               dbms_output.put_line(
                  'Job '
                  || l_job_id 
                  || ' successfully scheduled to execute every ' 
                  || mv_pause_job_run_interval 
                  || ' minutes.'); 
            else
               cwms_err.raise('ITEM_NOT_CREATED', 'job', l_job_id);
            end if;
         exception
            when others then
               cwms_err.raise('ITEM_NOT_CREATED', 'job', l_job_id || ':' || sqlerrm);
         end;
      end if;
   END start_timeout_mv_refresh_job;
   
--------------------------------------------------------
-- Return the current session user's primary office id
--
   function user_office_id
      return varchar2
   is
      l_office_id  varchar2 (16) := null;
      l_user_id    varchar2 (32);
   begin
      l_user_id := sys_context('userenv', 'session_user');
      begin
         select primary_office_id
           into l_office_id
           from at_sec_user_office
          where user_id = l_user_id;
      exception
         when no_data_found then
            begin
               select office_id 
                 into l_office_id 
                 from cwms_office 
                where eroc = upper(substr(l_user_id, 1, 2));
            exception when no_data_found then null;
            end;
      end;
      return l_office_id;
   end user_office_id;

--------------------------------------------------------
-- Return the current session user's primary office code
--
   function user_office_code
      return number
   is
      l_office_code number(10) := null;
      l_user_id     varchar2(32);
   begin
      l_user_id := sys_context('userenv', 'session_user');
      begin
         select office_code
           into l_office_code
           from cwms_office
          where office_id = 
                (select primary_office_id
                   from at_sec_user_office
                  where user_id = l_user_id);
      exception
         when no_data_found then
            begin
               select office_code 
                 into l_office_code 
                 from cwms_office 
                where eroc = upper(substr(l_user_id, 1, 2));
            exception when no_data_found then null;
            end;
      end;
      return l_office_code;
   end user_office_code;

--------------------------------------------------------
-- Return the office code for the specified office id,
-- or the user's primary office if the office id is null
--
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code   NUMBER := NULL;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_code := user_office_code;
      ELSE
         SELECT office_code
           INTO l_office_code
           FROM cwms_office
          WHERE office_id = p_office_id;
      END IF;
      RETURN l_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', p_office_id);
   END get_office_code;

--------------------------------------------------------
-- Return the db host office code for the specified office id,
-- or the user's primary office if the office id is null
--
   function get_db_office_code (p_office_id in varchar2 default null)
      return number
   is
      l_db_office_code number := null;
   begin
      select db_host_office_code
        into l_db_office_code
        from cwms_office
       where office_code = get_office_code(p_office_id);
         
      return l_db_office_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_OFFICE_ID', p_office_id);
   end get_db_office_code;
   
--------------------------------------------------------
-- Replace filename wildcard chars (?,*) with SQL ones
-- (_,%), using '\' as an escape character.
-- 
-- '?'  ==> '_' except when preceded by '\'
-- '*'  ==> '%' except when preceded by '\'
-- '\?' ==> '?'
-- '\*' ==> '*'
-- '\\' ==> '\'
--
   FUNCTION normalize_wildcards (p_string IN VARCHAR2)
      RETURN VARCHAR2
   is
      l_result varchar2(32767);
   begin
      l_result := nvl(p_string, '*');
      l_result := replace(l_result, '\\', chr(0));
      l_result := regexp_replace(regexp_replace(l_result, '(^|[^\])(\?)', '\1_'), '(^|[^\])(\*)', '\1%');
      l_result := regexp_replace(l_result, '\\([?*])', '\1');
      l_result := replace(l_result, chr(0), '\');
      return l_result;
   end normalize_wildcards;
      
   
   PROCEDURE TEST
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('successful test');
   END;

   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN p_base_id || SUBSTR ('-', 1, LENGTH (p_sub_id)) || p_sub_id;
   END;

--------------------------------------------------------------------------------
-- function get_time_zone_code
--
   function get_time_zone_code(
      p_time_zone_name in varchar2)
      return number
   is
      l_time_zone_code number(10);
   begin
      select time_zone_code
        into l_time_zone_code
        from cwms_time_zone
       where upper(time_zone_name) = upper(p_time_zone_name);

      return l_time_zone_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_TIME_ZONE', p_time_zone_name);
         
   end get_time_zone_code;

--------------------------------------------------------------------------------
-- function get_tz_usage_code
--
   function get_tz_usage_code(
      p_tz_usage_id in varchar2)
      return number
   is
      l_tz_usage_code number(10);
   begin
      select tz_usage_code
        into l_tz_usage_code
        from cwms_tz_usage
       where upper(tz_usage_id) = upper(nvl(p_tz_usage_id, 'Standard'));

      return l_tz_usage_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',p_tz_usage_id,'CWMS time zone usage');
         
   end get_tz_usage_code;

----------------------------------------------------------------------------
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80)
   IS
      i   PLS_INTEGER;
   BEGIN
      -- Dump (put_line) a character string p_str in chunks of length p_len
      i := 1;

      WHILE i < LENGTH (p_str)
      LOOP
         DBMS_OUTPUT.put_line (SUBSTR (p_str, i, p_len));
         i := i + p_len;
      END LOOP;
   END DUMP;

----------------------------------------------------------------------------
   PROCEDURE create_view
   IS
      l_sel   VARCHAR2 (120);
      l_sql   VARCHAR2 (4000);

      CURSOR c1
      IS
         SELECT *
           FROM at_ts_table_properties;
   BEGIN
      -- Create the partitioned timeseries table view

      -- Note: start_date and end_date are coded as ANSI DATE literals

      -- CREATE OR REPLACE FORCE VIEW AV_TSV AS
      -- select ts_code, date_time, data_entry_date, value, quality,
      --        DATE '2000-01-01' start_date, DATE '2001-01-01' end_date from IOT_2000
      -- union all
      -- select ts_code, date_time, data_entry_date, value, quality,
      --        DATE '2001-01-01' start_date, DATE '2002-01-01' end_date from IOT_2001
      l_sql := 'create or replace force view av_tsv as ';
      l_sel :=
         'select ts_code, date_time, version_date, data_entry_date, value, quality_code, DATE ''';

      FOR rec IN c1
      LOOP
         IF c1%ROWCOUNT > 1
         THEN
            l_sql := l_sql || ' union all ';
         END IF;

         l_sql :=
               l_sql
            || l_sel
            || TO_CHAR (rec.start_date, 'yyyy-mm-dd')
            || ''' start_date, DATE '''
            || TO_CHAR (rec.end_date, 'yyyy-mm-dd')
            || ''' end_date from '
            || rec.table_name;
      END LOOP;

      cwms_util.DUMP (l_sql);

      EXECUTE IMMEDIATE l_sql;
   EXCEPTION
      -- ORA-24344: success with compilation error
      WHEN OTHERS
      THEN
         --dbms_output.put_line(SQLERRM);
         RAISE;
   END create_view;
   
-------------------------------------------------------------------------------
-- function split_text(...)
--
--
   FUNCTION split_text (
      p_text      in varchar2,
      p_separator in varchar2 default null)
      return str_tab_t
   is
      l_str_tab str_tab_t := str_tab_t();
      l_str varchar2(32767);
      l_field varchar2(32767);
      l_pos binary_integer;
      l_sep varchar2(32767);
      l_sep_len binary_integer;
   begin
      if p_separator is null then
         l_str := regexp_replace(p_text, '\s+', ' ');
         l_sep := ' ';
      else
         l_str := p_text;
         l_sep := p_separator;
      end if;
      l_sep_len := length(l_sep);
      loop
         l_pos := nvl(instr(l_str, l_sep), 0);
         if l_pos = 0 then
            l_field := l_str;
            l_str   := null;
         else
            l_field := substr(l_str, 1, l_pos - 1);
            l_str := substr(l_str, l_pos + l_sep_len); -- null if > length(l_str)
         end if;
         l_str_tab.extend;
         l_str_tab(l_str_tab.last) := l_field;
         exit when l_pos = 0;
      end loop;
      return l_str_tab;
   end split_text;

-------------------------------------------------------------------------------
-- function join_text(...)
--
--
   FUNCTION join_text(
      p_text_tab  in str_tab_t,                      
      p_separator in varchar2 default null) 
      return varchar2
   is
      l_text varchar2(32767) := null;
   begin
      for i in 1 .. p_text_tab.count loop
         if i > 1 then
            l_text := l_text || p_separator;
         end if;
         l_text := l_text || p_text_tab(i);
      end loop;
      return l_text;
   end join_text;

-------------------------------------------------------------------------------
-- function parse_clob_recordset(...)
--
--
   FUNCTION parse_clob_recordset (p_clob IN  CLOB)
   return str_tab_tab_t
   is
      l_rows str_tab_t;
      l_tab str_tab_tab_t := str_tab_tab_t();
      l_buf varchar2(32767) := '';
      l_chunk varchar2(4000);
      l_clob_offset binary_integer := 1;
      l_buf_offset binary_integer := 1;
      l_amount binary_integer;
      l_clob_len binary_integer;
      l_last binary_integer;
      l_done_reading boolean;
      chunk_size constant binary_integer := 4000;
   begin  
      if p_clob is null then
         return null;
      end if;
      l_clob_len := dbms_lob.getlength(p_clob);
      l_amount := chunk_size;
      loop
         dbms_lob.read(p_clob, l_amount, l_clob_offset, l_chunk);
         l_clob_offset := l_clob_offset + l_amount;
         l_done_reading := l_clob_offset > l_clob_len;
         l_buf := l_buf || l_chunk;
         if instr(l_buf, record_separator) > 0  or l_done_reading then
            l_rows := split_text(l_buf, record_separator);
            l_buf := l_rows(l_rows.count);
            if l_done_reading then
               l_last := l_rows.count;
            else
               l_last := l_rows.count - 1;
            end if;
            for i in l_rows.first .. l_last loop
               l_tab.extend;
               l_tab(l_tab.last) := split_text(l_rows(i), field_separator);
            end loop;
         end if;
         exit when l_done_reading;
      end loop;    
      return l_tab;
   end parse_clob_recordset;
   
-------------------------------------------------------------------------------
-- function parse_string_recordset(...)
--
--
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
   return str_tab_tab_t
   is
      l_rows str_tab_t;
      l_tab str_tab_tab_t := str_tab_tab_t();
   begin
      if p_string is null then
         return null;
      end if;
      l_rows := split_text(p_string, record_separator);
      for i in l_rows.first .. l_rows.last loop
         l_tab.extend;
         l_tab(i) := split_text(l_rows(i), field_separator);
      end loop;
      return l_tab;
   end parse_string_recordset;
   
----------------------------------------------------------------------------
BEGIN
   -- anything put here will be executed on every mod_plsql call
   NULL;
END cwms_util;
/
show errors;



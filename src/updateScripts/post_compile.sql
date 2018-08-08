connect &cwms_schema/&cwms_passwd@&inst

PROMPT Updating location kinds

declare
   l_location_kind varchar2(32);                                                       
   l_type_str      varchar2(32);
begin
   ------------
   -- basins --
   ------------
   for rec in (select basin_location_code as code from at_basin) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'BASIN' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected BASIN');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'BASIN' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to BASIN'); 
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'BASIN'
                                )
          where location_code = rec.code;  
       end if;
   end loop;              
   -------------
   -- streams --
   -------------
   for rec in (select stream_location_code as code from at_stream) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'STREAM' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected STREAM');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'STREAM' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to STREAM');
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'STREAM'
                                )
          where location_code = rec.code;  
       end if;
   end loop;              
   -----------------
   -- embankments --
   -----------------
   for rec in (select embankment_location_code as code from at_embankment) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'EMBANKMENT' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected EMBANKMENT');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'EMBANKMENT' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to EMBANKMENT'); 
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'EMBANKMENT'
                                )
          where location_code = rec.code;  
       end if;
   end loop;              
   -----------
   -- locks --
   -----------
   for rec in (select lock_location_code as code from at_lock) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'LOCK' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected LOCK');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'LOCK' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to LOCK'); 
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'LOCK'
                                )
          where location_code = rec.code;  
       end if;
   end loop;              
   -------------
   -- outlets --
   -------------
   for rec in (select outlet_location_code as code from at_outlet) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'OUTLET' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected OUTLET');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'OUTLET' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to OUTLET');
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'OUTLET'
                                )
          where location_code = rec.code;  
       end if;
   end loop;              
   --------------
   -- projects --
   --------------
   for rec in (select project_location_code as code from at_project) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'PROJECT' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected PROJECT');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'PROJECT' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to PROJECT');
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'PROJECT'
                                )                                                       
          where location_code = rec.code;  
       end if;
   end loop;              
   --------------
   -- turbines --
   --------------
   for rec in (select turbine_location_code as code from at_turbine) loop
      begin
         l_type_str := cwms_loc.get_location_type(rec.code);
      exception
         when others then dbms_output.put_line(sqlerrm);
      end;
      if l_type_str != 'TURBINE' then
         dbms_output.put_line(cwms_loc.get_location_id(rec.code)||' is of type '||l_type_str||', expected TURBINE');
      end if; 
      select lk.location_kind_id
        into l_location_kind
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = rec.code
         and lk.location_kind_code = pl.location_kind;
       if l_location_kind != 'TURBINE' then
         dbms_output.put_line('Changing '||cwms_loc.get_location_id(rec.code)||' location kind to TURBINE');
         update at_physical_location
            set location_kind = (select location_kind_code 
                                   from cwms_location_kind 
                                  where location_kind_id = 'TURBINE'
                                )
          where location_code = rec.code;  
       end if;
   end loop;
end;         

/

whenever sqlerror continue;
update at_physical_location
      set location_kind = 1 -- UNSPECIFIED
    where location_kind is null;
   -----------------------------
   -- add not null constraint --
   -----------------------------
alter table at_physical_location modify (location_kind NUMBER(10)  not null);

PROMPT Adding VERTCON Data as CLOBs            

HOST sqlldr &cwms_schema/&cwms_passwd@&inst  updateScripts/vertcon_clobs.ctl

PROMPT Parsing VERTCON CLOBs into Tables            

declare
   l_clob          clob; 
   l_line          varchar2(32767);
   l_pos           integer; 
   l_pos2          integer; 
   l_parts         number_tab_t;
   l_lon_count     integer; 
   l_lat_count     integer; 
   l_z_count       integer; 
   l_min_lon       binary_double; 
   l_delta_lon     binary_double; 
   l_min_lat       binary_double;
   l_delta_lat     binary_double; 
   l_margin        binary_double;
   l_max_lon       binary_double;
   l_max_lat       binary_double;
   l_vals          number_tab_t := number_tab_t(); 
   l_data_set_code number(10);
   l_idx           pls_integer;
   
   procedure get_line(p_line out varchar2) is
      l_amount integer;
      l_buf    varchar2(32767);
   begin
      l_pos2 := dbms_lob.instr(l_clob, chr(10), l_pos, 1);
      if l_pos2 is null or l_pos2 = 0 then
         l_pos2 := dbms_lob.getlength(l_clob) + 1;
      else
         l_pos2 := l_pos2 + 1;
      end if;
      l_amount := greatest(l_pos2 - l_pos, 1);
      dbms_lob.read(l_clob, l_amount, l_pos, l_buf);
      l_pos := l_pos + l_amount;
      p_line := trim(trailing chr(13) from trim(trailing chr(10) from l_buf));
   end;  
begin
   ---------------------------
   -- for each vertcon clob --
   ---------------------------
   for rec in (select id from at_clob where clob_code < 0) loop          
      l_vals.delete;
      select value
        into l_clob
        from at_clob
       where id = upper(rec.id);
      dbms_lob.open(l_clob, dbms_lob.lob_readonly);
      l_pos := 1;       
      begin
         ---------------------
         -- read the header --
         ---------------------
         get_line(l_line); 
         get_line(l_line); 
         select column_value
           bulk collect
           into l_parts
           from table(cwms_util.split_text(trim(l_line)));
         if l_parts(3) != 1 then
            cwms_err.raise('ERROR', 'z_count must equal 1');
         end if;
         l_lon_count := l_parts(1);
         l_lat_count := l_parts(2);
         l_z_count   := l_parts(3);
         l_min_lon   := l_parts(4);
         l_delta_lon := l_parts(5);
         l_min_lat   := l_parts(6);
         l_delta_lat := l_parts(7);
         l_margin    := l_parts(8);
         l_max_lon := l_min_lon + (l_lon_count - 1) * l_delta_lon;
         l_max_lat := l_min_lat + (l_lat_count - 1) * l_delta_lat;
         l_vals.extend(l_lon_count * l_lat_count);
         ---------------------------------
         -- read the datum shift values --
         -- into a linear (1-D) table   --
         ---------------------------------
         l_idx := 0;
         <<read_vals>>
         while true loop
            begin
               get_line(l_line);   
               select column_value
                 bulk collect
                 into l_parts
                 from table(cwms_util.split_text(trim(l_line)));
               for j in 1..l_parts.count loop 
                  l_vals(l_idx+j) := l_parts(j);
               end loop;
               l_idx := l_idx + l_parts.count;
            exception
               when no_data_found then exit read_vals;
            end;
         end loop;
      exception
         when others then 
            dbms_lob.close(l_clob);
            raise;
      end;
      dbms_lob.close(l_clob);
      --------------------------
      -- load the header data --
      --------------------------
      insert
        into cwms_vertcon_header
             ( office_code,
               dataset_code,
               dataset_id,
               min_lat,
               max_lat,
               min_lon,
               max_lon,
               margin,
               delta_lat,
               delta_lon
             )
      values ( cwms_util.db_office_code_all,
               cwms_seq.nextval,
               replace(replace(lower(rec.id), 'asc', 'con'), '/vertcon/', ''),
               l_min_lat,
               l_max_lat,
               l_min_lon,
               l_max_lon,
               l_margin,
               l_delta_lat,
               l_delta_lon 
             )
   returning dataset_code
        into l_data_set_code;               
      -------------------------      
      -- load the table data --
      -------------------------      
      for j in 1..l_lat_count loop
         for k in 1..l_lon_count loop
            insert
              into cwms_vertcon_data
                   ( dataset_code,
                     table_row,
                     table_col,
                     table_val
                   )
            values ( l_data_set_code,
                     j,
                     k,
                     l_vals((j-1)*l_lon_count+k)
                   );
         end loop;
      end loop;      
   end loop;
   
   delete
     from at_clob
    where clob_code < 0;
    
   commit;    
end;
/

COMMIT;
--drop public synonym CWMS_ENV ;
whenever sqlerror exit;

BEGIN
   FOR c IN (SELECT owner, job_name
               FROM dba_scheduler_jobs
              WHERE owner = '&cwms_schema')
   LOOP
      BEGIN
         DBMS_OUTPUT.PUT_LINE (c.job_name);
         DBMS_SCHEDULER.ENABLE (c.owner || '.' || c.job_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/
prompt Dropping rating materialized views
whenever sqlerror continue;
begin
   dbms_scheduler.drop_job(job_name => 'UPDATE_RATING_MVIEWS_JOB', force => true);
end;
/
drop public synonym CWMS_V_MRATING_VALUES;
drop public synonym CWMS_V_MRATING_VALUES_NATIVE;
drop materialized view MV_RATING_VALUES;
drop materialized view MV_RATING_VALUES_NATIVE;

PROMPT refresh the at_cwms_ts_id table
BEGIN
  cwms_ts_id.refresh_at_cwms_ts_id;
  commit;
END;
/
CREATE PUBLIC SYNONYM CWMS_T_CWMS_TS_ID FOR CWMS_20.CWMS_TS_ID_T;
CREATE PUBLIC SYNONYM CWMS_T_DOUBLE_TAB_TAB_T FOR CWMS_20.DOUBLE_TAB_TAB_T;
CREATE PUBLIC SYNONYM CWMS_T_GROUP2 FOR CWMS_20.GROUP_TYPE2;
CREATE PUBLIC SYNONYM CWMS_T_LOC_ALIAS2 FOR CWMS_20.LOC_ALIAS_TYPE2;
CREATE PUBLIC SYNONYM CWMS_T_LOC_ALIAS3 FOR CWMS_20.LOC_ALIAS_TYPE3;
CREATE PUBLIC SYNONYM CWMS_T_LOOKUP_TYPE_OBJ_T FOR CWMS_20.LOOKUP_TYPE_OBJ_T;
CREATE PUBLIC SYNONYM CWMS_T_CWMS_TS_ID_ARRAY FOR CWMS_20.CWMS_TS_ID_ARRAY;
CREATE PUBLIC SYNONYM CWMS_T_GROUP2_ARRAY FOR CWMS_20.GROUP_ARRAY2;
CREATE PUBLIC SYNONYM CWMS_T_LOC_ALIAS2_ARRAY FOR CWMS_20.LOC_ALIAS_ARRAY2;
CREATE PUBLIC SYNONYM CWMS_T_LOC_ALIAS3_ARRAY FOR CWMS_20.LOC_ALIAS_ARRAY3;
CREATE PUBLIC SYNONYM CWMS_T_WAT_USR_CNTRCT_ACCT_OBJ FOR CWMS_20.WAT_USR_CONTRACT_ACCT_OBJ_T;
CREATE PUBLIC SYNONYM CWMS_T_WAT_USR_CNTRCT_ACCT_TAB FOR CWMS_20.WAT_USR_CONTRACT_ACCT_TAB_T;
ALTER TABLE CWMS_20.AT_VIRTUAL_RATING_ELEMENT
 ADD CONSTRAINT AT_VIRTUAL_RATING_ELEMENT_FK1 
  FOREIGN KEY (VIRTUAL_RATING_CODE) 
  REFERENCES CWMS_20.AT_VIRTUAL_RATING (VIRTUAL_RATING_CODE);
whenever sqlerror exit;

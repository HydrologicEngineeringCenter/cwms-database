create or replace package body cwms_schema
as

function get_hash_code(
   p_ddl in clob)
   return varchar2
is
begin
   return rawtohex(
      dbms_crypto.hash(
         regexp_replace(
            replace(
               p_ddl,
               '"&cwms_schema"',
               '"<cwms_schema>"'
            ),
            'SYS_[A-Z0-9_$]+',
            '<sys_defined_name>',
            1,
            0,
            'm'),
         dbms_crypto.hash_sh1));
end get_hash_code;

procedure set_schema_version(
   p_cwms_version  in varchar2,
   p_comments      in varchar2 default null)
is
   l_date_str     varchar2(19) := to_char(cast(systimestamp at time zone 'UTC' as date), 'yyyy/mm/dd hh24:mi:ss');
   l_object_names object_tab_t;

   procedure store_info(
      p_object_type in varchar2,
      p_object_name in varchar2)
   is
      l_hash_code varchar2(40);
      l_ddl       clob;
      l_sub_ddl   clob;
      l_code      number;
   begin
      l_ddl := dbms_metadata.get_ddl(p_object_type, p_object_name);
      for i in 1..dependent_type_names.count loop
         begin
            l_sub_ddl := dbms_metadata.get_dependent_ddl(dependent_type_names(i), p_object_name);
            dbms_lob.append(l_ddl, l_sub_ddl);
         exception
            when others then
            if l_sub_ddl is not null then
               dbms_lob.trim(l_sub_ddl, 0);
            end if;
         end;
      end loop;
      l_hash_code := get_hash_code(l_ddl);
      insert
        into cwms_schema_object_version
      values ( l_hash_code,
               p_object_type,
               p_object_name,
               l_date_str||' '||p_cwms_version,
               p_comments);
      cwms_text.store_text(l_code, l_ddl, '/DDL/'||l_hash_code, null, 'F', 'CWMS');
   end;
begin
   -----------------------------------
   -- check the list of table names --
   -----------------------------------
   select object_name bulk collect
     into l_object_names
     from user_objects
    where object_type = 'TABLE'
      and regexp_like(object_name, '(CWMS|AT)_.+')
 order by object_name;
   if l_object_names != table_names then
      cwms_err.raise('ERROR', 'Variable table_names is out of date');
   end if;
   ----------------------------------
   -- check the list of view names --
   ----------------------------------
   l_object_names.delete;
   select object_name bulk collect
     into l_object_names
     from user_objects
    where object_type = 'VIEW'
      and regexp_like(object_name, '(AV|ZAV|ZV)_.+')
 order by object_name;
   if l_object_names != view_names then
      cwms_err.raise('ERROR', 'Variable view_names is out of date');
   end if;
   -------------------------------------
   -- check the list of package names --
   -------------------------------------
   l_object_names.delete;
   select object_name bulk collect
     into l_object_names
     from user_objects
    where object_type = 'PACKAGE'
 order by object_name;
   if l_object_names != package_names then
      cwms_err.raise('ERROR', 'Variable package_names is out of date');
   end if;
   ----------------------------------
   -- check the list of type names --
   ----------------------------------
   l_object_names.delete;
   select object_name bulk collect
     into l_object_names
     from user_objects
    where object_type = 'TYPE'
      and object_name not like 'SYS\_%' escape '\'
 order by object_name;
   if l_object_names != type_names then
      cwms_err.raise('ERROR', 'Variable type_names is out of date');
   end if;
   ---------------------------------------
   -- check the list of type body names --
   ---------------------------------------
   l_object_names.delete;
   select object_name bulk collect
     into l_object_names
     from user_objects
    where object_type = 'TYPE BODY'
      and object_name not like 'SYS\_%' escape '\'
 order by object_name;
   if l_object_names != type_body_names then
      cwms_err.raise('ERROR', 'Variable type_body_names is out of date');
   end if;
   ---------------------------------------------------------------------------
   -- store the current hash code and the specified version for each object --
   ---------------------------------------------------------------------------
   dbms_output.put_line('Setting schema version to '||l_date_str||' '||p_cwms_version);
   for i in 1..table_names.count loop
      store_info('TABLE', table_names(i));
   end loop;
   for i in 1..view_names.count loop
      store_info('VIEW', view_names(i));
   end loop;
   for i in 1..package_names.count loop
      store_info('PACKAGE', package_names(i));
      store_info('PACKAGE_BODY', package_names(i));
   end loop;
   for i in 1..type_names.count loop
      store_info('TYPE', type_names(i));
   end loop;
   for i in 1..type_body_names.count loop
      store_info('TYPE_BODY', type_body_names(i));
   end loop;
   commit;
   --------------------------------------------------------------
   -- remove previous entries for objects that haven't changed --
   --------------------------------------------------------------
   cleanup_schema_version_table;
end set_schema_version;

procedure cleanup_schema_version_table
is
   l_old_ver sys_refcursor;
begin
   --------------------------------------------------------------
   -- remove previous entries for objects that haven't changed --
   --------------------------------------------------------------
      for l_old_ver in
      (with all_ as (select hash_code,
                             schema_version
                        from cwms_schema_object_version
                     ),
            cur_ as (select hash_code,
                             max(schema_version) as schema_version
                        from cwms_schema_object_version
                       group
                          by hash_code
                     )
       select all_.hash_code,
              all_.schema_version
         from all_,
              cur_
        where all_.hash_code       = cur_.hash_code
          and all_.schema_version != cur_.schema_version
      )
   loop
      delete
        from cwms_schema_object_version
       where hash_code = l_old_ver.hash_code
         and schema_version = l_old_ver.schema_version;
   end loop;
   commit;
end cleanup_schema_version_table;

procedure check_schema_version
is
   l_max_version varchar2(64);
   l_version     varchar2(64);
   l_hash_code   varchar2(40);
   l_message     varchar2(256);
   l_ddl         clob;

   function check_items(
      p_item_type in varchar2,
      p_items     in object_tab_t)
      return pls_integer
   is
      l_item_type varchar2(30) := upper(p_item_type);
      l_count     pls_integer  := 0;
      l_sub_ddl   clob;
   begin
      for i in 1..p_items.count loop
         begin
            l_ddl := dbms_metadata.get_ddl(l_item_type, p_items(i));
            for j in 1..dependent_type_names.count loop
               begin
                  l_sub_ddl := dbms_metadata.get_dependent_ddl(dependent_type_names(j), p_items(i));
                  dbms_lob.append(l_ddl, l_sub_ddl);
               exception
                  when others then
                  if l_sub_ddl is not null then
                     dbms_lob.trim(l_sub_ddl, 0);
                  end if;
               end;
            end loop;
            l_hash_code := get_hash_code(l_ddl);
            select max(schema_version)
              into l_version
              from cwms_schema_object_version
             where hash_code = l_hash_code
               and object_type = l_item_type
               and object_name = p_items(i);
            if l_version is null then
               l_count := l_count + 1;
               l_message := 'CHECK_SCHEMA_VERSION : '||l_item_type||' '||p_items(i)||' = unknown version.';
               cwms_msg.log_db_message(cwms_msg.msg_level_normal , l_message);
               dbms_output.put_line(l_message);
            elsif l_version  != l_max_version then
               l_count := l_count + 1;
               l_message := 'CHECK_SCHEMA_VERSION : '||l_item_type||' '||p_items(i)||' = version "'||l_version||'"';
               cwms_msg.log_db_message(cwms_msg.msg_level_normal , l_message);
               dbms_output.put_line(l_message);
            end if;
         exception
            when no_such_object then
               l_count := l_count + 1;
               l_message := 'CHECK_SCHEMA_VERSION : '||l_item_type||' '||p_items(i)||' does not exist.';
               cwms_msg.log_db_message(cwms_msg.msg_level_normal , l_message);
               dbms_output.put_line(l_message);
         end;
      end loop;
      return l_count;
   end;

begin
   dbms_output.enable(2000000);
   select max(schema_version)
     into l_max_version
     from cwms_schema_object_version;
   l_message := 'CHECK_SCHEMA_VERSION : Checking database objects against current version: '||l_max_version;
   cwms_msg.log_db_message(cwms_msg.msg_level_detailed , l_message);
   dbms_output.put_line(l_message);
   if check_items('table', table_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All tables are of the current version.');
   end if;
   if check_items('view', view_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All views are of the current version.');
   end if;
   if check_items('package', package_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All package specifications are of the current version.');
   end if;
   if check_items('package_body', package_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All package bodies are of the current version.');
   end if;
   if check_items('type', type_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All type specifications are of the current version.');
   end if;
   if check_items('type_body', type_body_names) = 0 then
      dbms_output.put_line('CHECK_SCHEMA_VERSION : All type bodies are of the current version.');
   end if;
   l_message := 'CHECK_SCHEMA_VERSION : Done';
   cwms_msg.log_db_message(cwms_msg.msg_level_detailed , l_message);
   dbms_output.put_line(l_message);
end check_schema_version;

procedure output_schema_versions
is
begin
   dbms_output.enable(2000000);
   for rec in (select * from cwms_schema_object_version) loop
      dbms_output.put_line(
         'insert into cwms_schema_object_version values ('''
         ||rec.hash_code
         ||''', '''||rec.object_type
         ||''', '''||rec.object_name
         ||''', '''||rec.schema_version
         ||''', '''||rec.comments||''');');
   end loop;
end output_schema_versions;

--------------------------------------------------------------------------------
-- procedure start_check_schema_job
--
procedure start_check_schema_job
is
   l_count        binary_integer;
   l_user_id      varchar2(30);
   l_job_id       varchar2(30)  := 'CHECK_SCHEMA_JOB';
   l_run_interval varchar2(8);
   l_comment      varchar2(256);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id and owner = l_user_id;

      return l_count;
   end;
begin
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   l_user_id := cwms_util.get_user_id;

   if l_user_id != '${CWMS_SCHEMA}'
   then
      raise_application_error (-20999,
                                  'Must be ${CWMS_SCHEMA} user to start job '
                               || l_job_id,
                               true
                              );
   end if;

   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0
   then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0
      then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         cwms_properties.get_property(
            l_run_interval,
            l_comment,
            'CWMSDB',
            'check_schema.interval',
            '1440',
            'CWMS');
         dbms_scheduler.create_job
            (job_name             => l_job_id,
             job_type             => 'stored_procedure',
             job_action           => 'cwms_schema.check_schema_version',
             start_date           => null,
             repeat_interval      => 'freq=hourly; interval=' || trunc(l_run_interval / 60),
             end_date             => null,
             job_class            => 'default_job_class',
             enabled              => true,
             auto_drop            => false,
             comments             => 'Checks CWMS schema against deployed version and logs differences'
            );

         if job_count = 1
         then
            dbms_output.put_line
                           (   'Job '
                            || l_job_id
                            || ' successfully scheduled to execute every '
                            || l_run_interval
                            || ' minutes.'
                           );
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others
         then
            cwms_err.raise ('ITEM_NOT_CREATED',
                            'job',
                            l_job_id || ':' || sqlerrm
                           );
      end;
   end if;

end start_check_schema_job;

function get_schema_version
   return varchar2
is
   l_schema_version varchar2(64);
begin
   select max(schema_version)
     into l_schema_version
     from cwms_schema_object_version;

   return l_schema_version;
end get_schema_version;

procedure output_latest_results
is
   l_min_id at_log_message.msg_id%type;
   l_max_id at_log_message.msg_id%type;
begin
   select max(msg_id)
     into l_max_id
     from at_log_message
    where msg_text = 'CHECK_SCHEMA_VERSION : Done';

   select max(msg_id)
     into l_min_id
     from at_log_message
    where msg_text like 'CHECK_SCHEMA_VERSION : Checking database objects against current version:%'
      and msg_id < l_max_id;

   for rec in
      (  select log_timestamp_utc,
                msg_text
           from at_log_message
          where msg_id between l_min_id and l_max_id
            and msg_text like 'CHECK_SCHEMA_VERSION%'
       order by log_timestamp_utc
      )
   loop
      dbms_output.put_line(to_char(rec.log_timestamp_utc, 'yyyy/mm/dd hh24:mi:ss : ')||substr(rec.msg_text, 24));
   end loop;
end output_latest_results;


function get_latest_hash(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return varchar2
is
   l_hash varchar2(64);
begin
   select hash_code
     into l_hash
     from cwms_schema_object_version
    where object_type = upper(p_object_type)
      and object_name = upper(p_object_name)
      and schema_version = (select max(schema_version)
                              from cwms_schema_object_version
                             where object_type = upper(p_object_type)
                               and object_name = upper(p_object_name)
                           );
   return l_hash;
end get_latest_hash;

function get_latest_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return clob
is
   l_ddl clob;
begin
   select value
     into l_ddl
     from at_clob
    where id = '/DDL/'||get_latest_hash(p_object_type, p_object_name);

   return l_ddl;
end get_latest_ddl;


function get_latest_static_data
   return clob
is
   l_max_schema_version varchar2(64);
   l_static_data        clob;
begin
   select max(schema_version)
     into l_max_schema_version
     from cwms_schema_object_version;

   select value
     into l_static_data
     from at_clob
    where id = '/DDL/STATIC_DATA/'||substr(l_max_schema_version, 21);

   return l_static_data;
end get_latest_static_data;

function get_current_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return clob
is
   l_ddl     clob;
   l_sub_ddl clob;
begin
   l_ddl := dbms_metadata.get_ddl(upper(p_object_type), upper(p_object_name));
   for i in 1..dependent_type_names.count loop
      begin
         l_sub_ddl := dbms_metadata.get_dependent_ddl(dependent_type_names(i), upper(p_object_name));
         dbms_lob.append(l_ddl, l_sub_ddl);
      exception
         when others then
         if l_sub_ddl is not null then
            dbms_lob.trim(l_sub_ddl, 0);
         end if;
      end;
   end loop;
   return l_ddl;
end get_current_ddl;

procedure compare_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2)
is
   l_object_type varchar2(30);
   l_object_name varchar2(30);
begin
   l_object_type := upper(p_object_type);
   l_object_name := upper(p_object_name);

   merge
    into at_schema_object_diff dst
   using (select l_object_type as object_type,
                 l_object_name as object_name,
                 max(schema_version) as deployed_version,
                 cwms_schema.get_latest_ddl (l_object_type, l_object_name) as deployed_ddl,
                 cwms_schema.get_current_ddl(l_object_type, l_object_name) as current_ddl
            from cwms_schema_object_version
           where object_type = l_object_type
             and object_name = l_object_name
         ) src
      on (dst.object_type = src.object_type and dst.object_name = src.object_name)
    when
 matched
    then update
            set dst.deployed_version = src.deployed_version,
                dst.deployed_ddl = src.deployed_ddl,
                dst.current_ddl = src.current_ddl
    when
     not
 matched
    then insert
         values (src.object_type,
                 src.object_name,
                 src.deployed_version,
                 src.deployed_ddl,
                 src.current_ddl
                );
end compare_ddl;

end cwms_schema;
/

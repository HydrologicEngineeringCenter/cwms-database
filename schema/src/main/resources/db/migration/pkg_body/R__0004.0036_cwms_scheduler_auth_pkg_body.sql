
create or replace package body cwms_scheduler_auth
as
--------------------------------------------------------------------------------
-- procedure store_auth_scheduler_entry
--------------------------------------------------------------------------------
procedure store_auth_scheduler_entry(
   p_job_owner     in varchar2,
   p_job_name      in varchar2,
   p_database_name in varchar2 default null)
is
   l_dbname    varchar2(61);
   l_auth_rec  cwms_auth_sched_entries%rowtype;
   l_sched_rec dba_scheduler_jobs%rowtype;
   l_exists    boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_job_owner is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_JOB_OWNER');
   end if;
   if p_job_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_JOB_NAME');
   end if;
   ---------------------------
   -- get the database name --
   ---------------------------
   if p_database_name is null then
      l_dbname := cwms_util.get_db_name;
   else
      l_dbname := upper(p_database_name);
   end if;
   --------------------------------------------
   -- get the entry from the scheduler table --
   --------------------------------------------
   begin
      select *
        into l_sched_rec
        from dba_scheduler_jobs
       where owner = upper(p_job_owner)
         and job_name = upper(p_job_name);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Scheduler job',
            l_dbname
            ||'/'
            ||upper(p_job_owner)
            ||':'
            ||upper(p_job_name));
   end;
   ----------------------------------------------------
   -- get the entry from the auth table if it exists --
   ----------------------------------------------------
   l_auth_rec.database_name := l_dbname;
   l_auth_rec.job_owner     := upper(p_job_owner);
   l_auth_rec.job_name      := upper(p_job_name);
   begin
      select *
        into l_auth_rec
        from cwms_auth_sched_entries
       where database_name = l_auth_rec.database_name
         and job_owner     = l_auth_rec.job_owner
         and job_name      = l_auth_rec.job_name;

      l_exists := true;
   exception
      when no_data_found then l_exists := false;
   end;
   ---------------------------------------------
   -- finish populating the auth_table_record --
   ---------------------------------------------
   l_auth_rec.job_creator     := l_sched_rec.job_creator;
   l_auth_rec.job_style       := l_sched_rec.job_style;
   l_auth_rec.job_type        := l_sched_rec.job_type;
   l_auth_rec.job_priority    := l_sched_rec.job_priority;
   l_auth_rec.schedule_type   := l_sched_rec.schedule_type;
   l_auth_rec.repeat_interval := l_sched_rec.repeat_interval;
   l_auth_rec.comments        := l_sched_rec.comments;
   l_auth_rec.job_action      := l_sched_rec.job_action;
   ---------------------------------------------------
   -- update or insert the record in the auth table --
   ---------------------------------------------------
   if l_exists then
      update cwms_auth_sched_entries
         set row = l_auth_rec
       where database_name = l_auth_rec.database_name
         and job_owner     = l_auth_rec.job_owner
         and job_name      = l_auth_rec.job_name;
   else
      insert
        into cwms_auth_sched_entries
      values l_auth_rec;
   end if;

end store_auth_scheduler_entry;

--------------------------------------------------------------------------------
-- procedure delete_auth_scheduler_entry
--------------------------------------------------------------------------------
procedure delete_auth_scheduler_entry(
   p_job_owner     in varchar2,
   p_job_name      in varchar2,
   p_database_name in varchar2 default null)
is
   l_dbname varchar2(61);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_job_owner is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_JOB_OWNER');
   end if;
   if p_job_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_JOB_NAME');
   end if;
   ---------------------------
   -- get the database name --
   ---------------------------
   if p_database_name is null then
      l_dbname := cwms_util.get_db_name;
   else
      l_dbname := upper(p_database_name);
   end if;
   ----------------------
   -- delete the entry --
   ----------------------
   begin
      delete
        from cwms_auth_sched_entries
       where database_name = l_dbname
         and job_owner     = upper(p_job_owner)
         and job_name      = upper(p_job_name);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Scheduler job authorization',
            l_dbname
            ||'/'
            ||upper(p_job_owner)
            ||':'
            ||upper(p_job_name));
   end;
end delete_auth_scheduler_entry;

--------------------------------------------------------------------------------
-- procedure cat_auth_scheduler_entries
--------------------------------------------------------------------------------
procedure cat_auth_scheduler_entries(
   p_cat_cursor         out sys_refcursor,
   p_job_owner_mask     in  varchar2 default '*',
   p_job_name_mask      in  varchar2 default '*',
   p_database_name_mask in  varchar2 default null)
is
   l_job_owner_mask     varchar2(30);
   l_job_name_mask      varchar2(30);
   l_database_name_mask varchar2(61);
begin
   --------------------------------
	-- get the selection criteria --
   --------------------------------
   l_job_owner_mask := cwms_util.normalize_wildcards(nvl(upper(p_job_owner_mask), '*'));
   l_job_name_mask  := cwms_util.normalize_wildcards(nvl(upper(p_job_name_mask),  '*'));
   if p_database_name_mask is null then
     l_database_name_mask := cwms_util.get_db_name;
   else
      l_database_name_mask := cwms_util.normalize_wildcards(nvl(upper(p_database_name_mask),  '*'));
   end if;
   ---------------------------
   -- perform the selection --
   ---------------------------
   open p_cat_cursor for
      select database_name,
             job_owner,
             job_name,
             job_creator,
             job_style,
             job_type,
             job_priority,
             schedule_type,
             repeat_interval,
             comments,
             job_action
        from cwms_auth_sched_entries
       where database_name like l_database_name_mask escape '\'
         and job_owner     like l_job_owner_mask     escape '\'
         and job_name      like l_job_name_mask      escape '\';

end cat_auth_scheduler_entries;

--------------------------------------------------------------------------------
-- function cat_auth_scheduler_entries_f
--------------------------------------------------------------------------------
function cat_auth_scheduler_entries_f(
   p_job_owner_mask     in varchar2 default '*',
   p_job_name_mask      in varchar2 default '*',
   p_database_name_mask in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_auth_scheduler_entries(
      l_cat_cursor,
      p_job_owner_mask,
      p_job_name_mask,
      p_database_name_mask);

   return l_cat_cursor;
end cat_auth_scheduler_entries_f;

--------------------------------------------------------------------------------
-- procedure cat_unauth_scheduler_entries
--------------------------------------------------------------------------------
procedure cat_unauth_scheduler_entries(
   p_cat_cursor         out sys_refcursor,
   p_job_owner_mask     in  varchar2 default '*',
   p_job_name_mask      in  varchar2 default '*',
   p_database_name_mask in  varchar2 default null)
is
   l_job_owner_mask     varchar2(30);
   l_job_name_mask      varchar2(30);
   l_database_name_mask varchar2(61);
begin
   --------------------------------
	-- get the selection criteria --
   --------------------------------
   l_job_owner_mask := cwms_util.normalize_wildcards(nvl(upper(p_job_owner_mask), '*'));
   l_job_name_mask  := cwms_util.normalize_wildcards(nvl(upper(p_job_name_mask),  '*'));
   if p_database_name_mask is null then
      l_database_name_mask := cwms_util.get_db_name;
   else
      l_database_name_mask := cwms_util.normalize_wildcards(nvl(upper(p_database_name_mask),  '*'));
   end if;
   ---------------------------
   -- perform the selection --
   ---------------------------
   open p_cat_cursor for
      select database_name,
             job_owner,
             job_name,
             first_detected,
             job_creator,
             job_style,
             job_type,
             job_priority,
             schedule_type,
             repeat_interval,
             comments,
             job_action
        from cwms_unauth_sched_entries
       where database_name like l_database_name_mask escape '\'
         and job_owner     like l_job_owner_mask     escape '\'
         and job_name      like l_job_name_mask      escape '\';
end cat_unauth_scheduler_entries;

--------------------------------------------------------------------------------
-- function cat_unauth_scheduler_entries_f
--------------------------------------------------------------------------------
function cat_unauth_scheduler_entries_f(
   p_job_owner_mask     in varchar2 default '*',
   p_job_name_mask      in varchar2 default '*',
   p_database_name_mask in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_unauth_scheduler_entries(
      l_cat_cursor,
      p_job_owner_mask,
      p_job_name_mask,
      p_database_name_mask);

   return l_cat_cursor;
end cat_unauth_scheduler_entries_f;

--------------------------------------------------------------------------------
-- procedure store_email_recipients
--------------------------------------------------------------------------------
procedure store_email_recipients(
   p_email_recipients in str_tab_t)
is
   l_recipients_str varchar2(32767);
   l_recipients     str_tab_t;
begin
   ------------------------------------
   -- delete the existing recipients --
   ------------------------------------
   delete_email_recipients;
   if p_email_recipients is not null then
      select trim(column_value)
        bulk collect
        into l_recipients
        from table(p_email_recipients);
      ----------------------------------------------
      -- get a comma-separated list of recipients --
      ----------------------------------------------
      l_recipients_str := cwms_util.join_text(l_recipients, ',');
      --------------------------------------------------------
      -- break up the list into table of lists <= 256 chars --
      --------------------------------------------------------
      l_recipients.delete;
      while l_recipients_str is not null loop
         l_recipients.extend;
         if length(l_recipients_str) > 256 then
            for pos in reverse 1..256 loop
               if substr(l_recipients_str, pos, 1) = ',' then
                  l_recipients(l_recipients.count) := substr(l_recipients_str, 1, pos-1);
                  l_recipients_str := substr(l_recipients_str, pos+1);
                  exit;
               end if;
            end loop;
         else
            l_recipients(l_recipients.count) := l_recipients_str;
            l_recipients_str := null;
         end if;
      end loop;
      -----------------------------------------------------
      -- set the property for each sub-list in the table --
      -----------------------------------------------------
      for i in 1..l_recipients.count loop
         cwms_properties.set_property(
            recipients_prop_category,
            recipients_prop_name||'.'||i,
            l_recipients(i),
            null,
            recipients_prop_office);
      end loop;
      --------------------------------------------------
      -- set the property for the number of sub-lists --
      --------------------------------------------------
      cwms_properties.set_property(
         recipients_prop_category,
         recipients_prop_name||'.count',
         l_recipients.count,
         null,
         recipients_prop_office);
   end if;
end store_email_recipients;

--------------------------------------------------------------------------------
-- procedure store_email_recipients
--------------------------------------------------------------------------------
procedure store_email_recipients(
   p_email_recipients in varchar2)
is
begin
	store_email_recipients(cwms_util.split_text(p_email_recipients, ','));
end store_email_recipients;

--------------------------------------------------------------------------------
-- procedure add_email_recipient
--------------------------------------------------------------------------------
procedure add_email_recipient(
   p_email_recipient in varchar2)
is
   l_recipients str_tab_t;
   l_count      integer;
begin
	if p_email_recipient is not null then
      l_recipients := retrieve_email_recipients_f;
      select count(*)
        into l_count
        from table(l_recipients)
       where column_value = p_email_recipient;
      if l_count = 0 then
         l_recipients.extend;
         l_recipients(l_recipients.count) := p_email_recipient;
         store_email_recipients(l_recipients);
      end if;
   end if;
end add_email_recipient;

--------------------------------------------------------------------------------
-- procedure delete_email_recipient
--------------------------------------------------------------------------------
procedure delete_email_recipient(
   p_email_recipient in varchar2)
is
   l_recipients1 str_tab_t;
   l_recipients2 str_tab_t;
begin
	if p_email_recipient is not null then
      l_recipients1 := retrieve_email_recipients_f;
      select column_value
        bulk collect
        into l_recipients2
        from table(l_recipients1)
       where column_value != p_email_recipient;

      if l_recipients2.count < l_recipients1.count then
         store_email_recipients(l_recipients2);
      end if;
   end if;
end delete_email_recipient;

--------------------------------------------------------------------------------
-- procedure delete_email_recipients
--------------------------------------------------------------------------------
procedure delete_email_recipients
is
   l_count integer;
begin
   l_count := to_number(cwms_properties.get_property(
      recipients_prop_category,
      recipients_prop_name||'.count',
      0,
      recipients_prop_office));
   for i in 1..l_count loop
      cwms_properties.delete_property(
         recipients_prop_category,
         recipients_prop_name||'.'||i,
         recipients_prop_office);
   end loop;
end delete_email_recipients;

--------------------------------------------------------------------------------
-- procedure retrieve_email_recipients
--------------------------------------------------------------------------------
procedure retrieve_email_recipients(
   p_email_recipients out str_tab_t)
is
   l_recipients_str varchar2(32767);
   l_count          integer;
   l_prop_text      varchar2(256);
begin
   l_count := to_number(cwms_properties.get_property(
      recipients_prop_category,
      recipients_prop_name||'.count',
      0,
      recipients_prop_office));
   for i in 1..l_count loop
      l_prop_text := cwms_properties.get_property(
         recipients_prop_category,
         recipients_prop_name||'.'||i,
         null,
         recipients_prop_office);
      if l_prop_text is not null then
         if l_recipients_str is not null then
            l_recipients_str := l_recipients_str||',';
         end if;
         l_recipients_str := l_recipients_str||l_prop_text;
      end if;
   end loop;
   p_email_recipients := cwms_util.split_text(l_recipients_str, ',');
end retrieve_email_recipients;

--------------------------------------------------------------------------------
-- function retrieve_email_recipients_f
--------------------------------------------------------------------------------
function retrieve_email_recipients_f
   return str_tab_t
is
   l_email_recipients str_tab_t;
begin
	retrieve_email_recipients(l_email_recipients);
   return l_email_recipients;
end retrieve_email_recipients_f;

--------------------------------------------------------------------------------
-- procedure cat_email_recipients
--------------------------------------------------------------------------------
procedure cat_email_recipients(
   p_cat_cursor out sys_refcursor)
is
begin
	open p_cat_cursor for select column_value as recipient from table(retrieve_email_recipients_f);
end cat_email_recipients;

--------------------------------------------------------------------------------
-- function cat_email_recipients_f
--------------------------------------------------------------------------------
function cat_email_recipients_f
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
	cat_email_recipients(l_cat_cursor);
   return l_cat_cursor;
end cat_email_recipients_f;

--------------------------------------------------------------------------------
-- procedure check_scheduler_entries
--------------------------------------------------------------------------------
procedure check_scheduler_entries
is
   l_message     varchar2(32767);
   l_to_addrs    varchar2(32767);
   l_dbname      varchar2(61);
   l_count       pls_integer := 0;
   l_rec         cwms_unauth_sched_entries%rowtype;

   function encode(l_raw in varchar2)
   return varchar2
   is
   begin
      return replace(replace(replace(replace(replace(l_raw, '&', '&amp;'), '>', '&gt;'), '<', '&lt;'), '''', '&apos;'), '"', '&quot;');
   end encode;
begin
   -----------------------------------
   -- get the primary database name --
   -----------------------------------
   l_dbname := cwms_util.get_db_name;
   -----------------------------
   -- get the email addresses --
   -----------------------------
   l_to_addrs := cwms_util.join_text(retrieve_email_recipients_f, ',');
   ----------------------------------------------
   -- loop over unauthorized scheduler entries --
   ----------------------------------------------
   for rec in (select owner,
                      job_name,
                      job_creator,
                      job_style,
                      job_type,
                      state,
                      job_priority,
                      schedule_type,
                      start_date,
                      repeat_interval,
                      last_start_date,
                      last_run_duration,
                      next_run_date,
                      comments,
                      job_action
                 from dba_scheduler_jobs
                where 'SYS' not in (owner, job_creator)
                  and state <> 'DISABLED'
                  and (owner,
                       job_creator,
                       job_name,
                       job_style,
                       job_type,
                       job_priority,
                       schedule_type,
                       repeat_interval,
                       comments,
                       job_action
                      ) not in
                      (select job_owner,
                              job_creator,
                              job_name,
                              job_style,
                              job_type,
                              job_priority,
                              schedule_type,
                              repeat_interval,
                              comments,
                              job_action
                         from cwms_auth_sched_entries
                        where database_name in (l_dbname, 'CWMS')
                      )
                order by 1, 2, 3
              )
   loop
      ------------------------------------------------------------
      -- add or update entry in cwms_unauth_sched_entries table --
      ------------------------------------------------------------
      begin
         select *
           into l_rec
           from cwms_unauth_sched_entries
          where database_name = l_dbname
            and job_owner = rec.owner
            and job_name = rec.job_name;

            l_rec.first_detected     := sysdate;
            l_rec.job_creator        := rec.job_creator;
            l_rec.job_style          := rec.job_style;
            l_rec.job_type           := rec.job_type;
            l_rec.job_priority       := rec.job_priority;
            l_rec.schedule_type      := rec.schedule_type;
            l_rec.repeat_interval    := rec.repeat_interval;
            l_rec.comments           := rec.comments;
            l_rec.job_action         := rec.job_action;

            update cwms_unauth_sched_entries
               set row = l_rec
          where database_name = l_rec.database_name
            and job_owner = l_rec.job_owner
            and job_name = l_rec.job_name;
      exception
         when no_data_found then
            insert
              into cwms_unauth_sched_entries
            values (l_dbname,
                    rec.owner,
                    rec.job_name,
                    sysdate,
                    rec.job_creator,
                    rec.job_style,
                    rec.job_type,
                    rec.job_priority,
                    rec.schedule_type,
                    rec.repeat_interval,
                    rec.comments,
                    rec.job_action
                   );
      end;
      if l_to_addrs is not null then
         ----------------------
         -- build email body --
         ----------------------
         l_count := l_count + 1;
         if l_count = 1 then
            l_message := l_message||'<html><body><h3>Unauthorized Database Scheduler Entries at '||l_dbname||'</h3>';
            l_message := l_message||'<h3>'||sysdate||' UTC</h3><table>';
         end if;
         l_message := l_message||'<tr><th colspan="2" bgcolor="black"></th></tr>';
         l_message := l_message||'<tr><th align="left" bgcolor="darkkhaki">Owner</th><td bgcolor="khaki">'  ||encode(rec.owner)            ||'</td></tr>';
         l_message := l_message||'<tr><th align="left" bgcolor="darkkhaki">Creator</th><td bgcolor="khaki">'||encode(rec.job_creator)      ||'</td></tr>';
         l_message := l_message||'<tr><th align="left" bgcolor="darkkhaki">Name</th><td bgcolor="khaki">'   ||encode(rec.job_name)         ||'</td></tr>';
         l_message := l_message||'<tr><th align="left" bgcolor="darkkhaki">Action</th><td bgcolor="khaki">' ||encode(rec.job_action)       ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Style</th><td>'                                      ||encode(rec.job_style)        ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Type</th><td>'                                       ||encode(rec.job_type)         ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">State</th><td>'                                      ||encode(rec.state)            ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Priority</th><td>'                                   ||encode(rec.job_priority)     ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Schedule</th><td>'                                   ||encode(rec.schedule_type)    ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Start</th><td>'                                      ||encode(rec.start_date)       ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Repeat</th><td>'                                     ||encode(rec.repeat_interval)  ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Last&nbsp;Start</th><td>'                            ||encode(rec.last_start_date)  ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Last&nbsp;Duration</th><td>'                         ||encode(rec.last_run_duration)||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Next&nbsp;Start</th><td>'                            ||encode(rec.next_run_date)    ||'</td></tr>';
         l_message := l_message||'<tr><th align="left">Comments</th><td>'                                   ||encode(rec.comments)         ||'</td></tr>';
      end if;
   end loop;
   if l_message is not null then
      l_message := l_message||'</table></body></html>';
   end if;
   ----------------
   -- send email --
   ----------------
   cwms_mail.send_mail(
      p_from       => lower(l_dbname)||'.db.cwms@usace.army.mil',
      p_to         => l_to_addrs,
      p_subject    => l_count||' Unauthorized Database Scheduler Entries',
      p_message    => l_message,
      p_is_html    => 'T');
   ----------------------------------------------------------------------------
   -- delete any authorized scheduler entries from cwms_unauth_sched_entries --
   ----------------------------------------------------------------------------
   delete
     from cwms_unauth_sched_entries
    where (database_name,
           job_owner,
           job_name
          ) in (select l_dbname,
                       job_owner,
                       job_name
                  from cwms_auth_sched_entries
               );
end check_scheduler_entries;

function job_count
   return pls_integer
is
   l_count pls_integer;
begin
   select count (*) into l_count from sys.dba_scheduler_jobs where job_name = monitor_scheduler_job_name;
   return l_count;
end job_count;

procedure start_check_sched_entries_job
is
   l_office_id varchar2(16);
begin
   l_office_id := cwms_util.user_office_id;
   if l_office_id != 'CWMS' then
      cwms_err.raise('ERROR', 'Must be logged in as schema owner to start job');
   end if;
   stop_check_sched_entries_job;
   dbms_scheduler.create_job(
      job_name             => monitor_scheduler_job_name,
      job_type             => 'stored_procedure',
      job_action           => 'cwms_scheduler_auth.check_scheduler_entries',
      number_of_arguments  => 0,
      start_date           => from_tz(trunc(sysdate)+10/24, 'UTC'), -- 10:00 UTC
      repeat_interval      => 'freq=daily; interval=1',
      end_date             => null,
      job_class            => 'default_job_class',
      enabled              => true,
      auto_drop            => false,
      comments             => 'Monitors scheduler for unauthorized entries');

   if job_count = 0 then
      cwms_err.raise('ERROR', 'Could not start '||monitor_scheduler_job_name);
   end if;

end start_check_sched_entries_job;

procedure stop_check_sched_entries_job
is
   l_office_id varchar2(16);
begin
   l_office_id := cwms_util.user_office_id;
   if l_office_id != 'CWMS' then
      cwms_err.raise('ERROR', 'Must be logged in as schema owner to stop '||monitor_scheduler_job_name);
   end if;

   if job_count > 0 then
      dbms_scheduler.drop_job(job_name => monitor_scheduler_job_name, force => true);
   end if;

   if job_count > 0 then
      cwms_err.raise('ERROR', 'Could not stop '||monitor_scheduler_job_name);
   end if;

end stop_check_sched_entries_job;

end cwms_scheduler_auth;
/

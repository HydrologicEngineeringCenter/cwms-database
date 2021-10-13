create or replace package body cwms_log_ingest
as
--------------------------------------------------------------------------------
-- PROCEDURE STORE_APP_LOG_DIR
--------------------------------------------------------------------------------
procedure store_app_log_dir(
   p_host_fqdn      in varchar2,
   p_log_dir        in varchar2,
   p_fail_if_exists in varchar2 default 'F',
   p_office_id      in varchar2 default null)
is
   l_fail_if_exists boolean;
   l_host_fqdn      at_app_log_dir.host_fqdn%type;
   l_log_dir        at_app_log_dir.log_dir_name%type;
   l_office_code    integer;
   l_count          integer;
   l_exists         boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_dir is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_DIR');
   end if;
   if p_fail_if_exists is null then
      cwms_err.raise('NULL_ARGUMENT', 'L_FAIL_IF_EXISTS');
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   -----------------
   -- do the work --
   -----------------
   l_host_fqdn := lower(p_host_fqdn);
   l_log_dir := p_log_dir;
   if regexp_like(l_log_dir, '.+[/\]$') then
      l_log_dir := substr(l_log_dir, 1, length(l_log_dir)-1);
   end if;
   select count(*)
     into l_count
     from at_app_log_dir
    where host_fqdn = l_host_fqdn
      and log_dir_name = l_log_dir
      and office_code = l_office_code;
   l_exists := l_count = 1;
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Application log directory',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||l_log_dir);
      else
         null;
      end if;
   else
      insert
        into at_app_log_dir
      values (cwms_seq.nextval, l_office_code, l_host_fqdn, l_log_dir);
   end if;
end store_app_log_dir;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_APP_LOG_DIR
--------------------------------------------------------------------------------
procedure delete_app_log_dir(
   p_host_fqdn     in varchar2,
   p_log_dir       in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir       at_app_log_dir.log_dir_name%type;
   l_delete_action varchar2(32);
   l_office_code   integer;
   l_log_dir_code  integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_dir is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_DIR');
   end if;
   if p_delete_action is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DELETE_ACTION');
   end if;
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_delete_action := upper(p_delete_action);
   if l_delete_action not in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be one of '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'''');
   end if;
   -----------------
   -- do the work --
   -----------------
   l_host_fqdn := lower(p_host_fqdn);
   l_log_dir := p_log_dir;
   if regexp_like(l_log_dir, '.+[/\]$') then
      l_log_dir := substr(l_log_dir, 1, length(l_log_dir)-1);
   end if;
   begin
      select log_dir_code
        into l_log_dir_code
        from at_app_log_dir
       where host_fqdn = l_host_fqdn
         and log_dir_name = l_log_dir
         and office_code = l_office_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Application log directory',
            cwms_util.get_db_office_id(l_office_code)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||l_log_dir);
   end;
   if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      ---------------------
      -- delete the data --
      ---------------------
      delete
        from at_app_log_entry
       where log_file_code in
             (select log_file_code
                from at_app_log_file
               where log_dir_code = l_log_dir_code
             );
      delete
        from at_app_log_file
       where log_dir_code = l_log_dir_code;
   end if;
   if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      --------------------
      -- delete the key --
      --------------------
      delete
        from at_app_log_dir
       where log_dir_code = l_log_dir_code;
   end if;
end delete_app_log_dir;
--------------------------------------------------------------------------------
-- PROCEDURE CAT_APP_LOG_DIR
--------------------------------------------------------------------------------
procedure cat_app_log_dir(
   p_cat_cursor      out sys_refcursor,
   p_host_mask       in  varchar2 default '*',
   p_log_dir_mask    in  varchar2 default '*',
   p_office_id_mask  in  varchar2 default null)
is
begin
   open p_cat_cursor for
      select o.office_id,
             d.host_fqdn,
             d.log_dir_name
        from at_app_log_dir d,
             cwms_office o
       where d.host_fqdn like cwms_util.normalize_wildcards(lower(nvl(p_host_mask, '*'))) escape '\'
         and d.log_dir_name like cwms_util.normalize_wildcards(nvl(p_log_dir_mask, '*')) escape '\'
         and o.office_id like cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id)) escape '\'
         and d.office_code = o.office_code;
end cat_app_log_dir;
--------------------------------------------------------------------------------
-- FUNCTION CAT_APP_LOG_DIR_F
--------------------------------------------------------------------------------
function cat_app_log_dir_f(
   p_host_mask       in varchar2 default '*',
   p_log_dir_mask    in varchar2 default '*',
   p_office_id_mask  in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_app_log_dir(
      l_cat_cursor,
      p_host_mask,
      p_log_dir_mask,
      p_office_id_mask);
   return l_cat_cursor;
end cat_app_log_dir_f;
--------------------------------------------------------------------------------
-- STORE_APP_LOG_FILE
--------------------------------------------------------------------------------
procedure store_app_log_file(
   p_host_fqdn      in varchar2,
   p_log_file_name  in varchar2,
   p_fail_if_exists in varchar2 default 'F',
   p_office_id      in varchar2 default null)
is
   l_fail_if_exists boolean;
   l_host_fqdn      at_app_log_dir.host_fqdn%type;
   l_log_dir        at_app_log_dir.log_dir_name%type;
   l_log_file_name  at_app_log_file.log_file_name%type;
   l_office_code    integer;
   l_count          integer;
   l_pos            integer;
   l_dir_code       integer;
   l_exists         boolean;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   if p_fail_if_exists is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_FAIL_IF_EXISTS');
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_host_fqdn := lower(p_host_fqdn);
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ------------------------------------------------------------------------
   -- store the directory if it doesn't exist (will roll back on error)  --
   ------------------------------------------------------------------------
   begin
      select log_dir_code
        into l_dir_code
        from at_app_log_dir
       where host_fqdn = l_host_fqdn
         and log_dir_name = l_log_dir
         and office_code = l_office_code;
   exception
      when no_data_found then
         insert into at_app_log_dir
         values (cwms_seq.nextval, l_office_code, l_host_fqdn, l_log_dir)
      returning log_dir_code into l_dir_code;
   end;
   ----------------------------
   -- see if the file exists --
   ----------------------------
   select count(*)
     into l_count
     from at_app_log_file
    where log_dir_code = l_dir_code
      and log_file_name = l_log_file_name;
   l_exists := l_count = 1;
   --------------------------------
   -- barf, store, or do nothing --
   --------------------------------
   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Application log file',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||l_log_dir
            ||case when instr(l_log_dir, '/') > 0 then '/' else '\' end
            ||l_log_file_name);
      else
         null;
      end if;
   else
      insert
        into at_app_log_file
      values (cwms_seq.nextval, l_dir_code, l_log_file_name);
   end if;
end store_app_log_file;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_APP_LOG_TEXT
--------------------------------------------------------------------------------
procedure delete_app_log_text(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir       at_app_log_dir.log_dir_name%type;
   l_log_file_name at_app_log_file.log_file_name%type;
   l_delete_action varchar2(32);
   l_office_code   integer;
   l_count         integer;
   l_pos           integer;
   l_log_dir_code  integer;
   l_log_file_code integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   if p_delete_action is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_DELETE_ACTION');
   end if;
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_delete_action := upper(p_delete_action);
   if l_delete_action not in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be one of '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'''');
   end if;
   l_office_code := cwms_util.get_db_office_code(p_office_id);
   l_host_fqdn := lower(p_host_fqdn);
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   begin
      select log_dir_code
        into l_log_dir_code
        from at_app_log_dir
       where host_fqdn = l_host_fqdn
         and log_dir_name = l_log_dir
         and office_code = l_office_code;
      select log_file_code
        into l_log_file_code
        from at_app_log_file
       where log_dir_code = l_log_dir_code
         and log_file_name = l_log_file_name;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Application log file',
            cwms_util.get_db_office_id(l_office_code)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_file_name);
   end;
   if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      ---------------------
      -- delete the data --
      ---------------------
      delete
        from at_app_log_entry
       where log_file_code = l_log_file_code;
   end if;
   if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      --------------------
      -- delete the key --
      --------------------
      delete
        from at_app_log_file
       where log_file_code = l_log_file_code;
   end if;
end delete_app_log_text;
--------------------------------------------------------------------------------
-- PROCEDURE CAT_APP_LOG_FILE
--------------------------------------------------------------------------------
procedure cat_app_log_file(
   p_cat_cursor      out sys_refcursor,
   p_host_mask       in  varchar2 default '*',
   p_log_file_mask   in  varchar2 default '*',
   p_office_id_mask  in  varchar2 default null)
is
begin
   open p_cat_cursor for
      select o.office_id,
             d.host_fqdn,
             d.log_dir_name,
             f.log_file_name
        from at_app_log_file f,
             at_app_log_dir d,
             cwms_office o
       where d.host_fqdn like cwms_util.normalize_wildcards(lower(nvl(p_host_mask, '*'))) escape '\'
         and f.log_dir_code = d.log_dir_code
         and case
             when instr(d.log_dir_name, '/') > 0 then d.log_dir_name||'/'||f.log_file_name
             else d.log_dir_name||'\'||f.log_file_name
             end
             like cwms_util.normalize_wildcards(nvl(p_log_file_mask, '*')) escape '\'
         and o.office_id like cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id)) escape '\'
         and d.office_code = o.office_code;
end cat_app_log_file;
--------------------------------------------------------------------------------
-- FUNCTION CAT_APP_LOG_FILE_F
--------------------------------------------------------------------------------
function cat_app_log_file_f(
   p_host_mask       in varchar2 default '*',
   p_log_file_mask   in varchar2 default '*',
   p_office_id_mask  in varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_app_log_file(
      l_cat_cursor,
      p_host_mask,
      p_log_file_mask,
      p_office_id_mask);
   return l_cat_cursor;
end cat_app_log_file_f;
--------------------------------------------------------------------------------
-- PROCEDURE STORE_APP_LOG_INGEST_CONTROL
--------------------------------------------------------------------------------
procedure store_app_log_ingest_control(
   p_host_fqdn          in varchar2,
   p_log_dir            in varchar2,
   p_log_file_mask      in varchar2 default '*',
   p_ingest_sub_dirs    in varchar2 default 'F',
   p_max_entry_age      in varchar2 default 'P1M',
   p_max_file_size      in integer  default 50 * 1024 * 1024,
   p_delete_empty_files in varchar2 default 'T',
   p_fail_if_exists     in varchar2 default 'T',
   p_office_id          in varchar2 default null)
is
   l_host_fqdn          at_app_log_dir.host_fqdn%type;
   l_log_file_mask      at_app_log_ingest_control.ingest_file_name_mask%type;
   l_max_entry_age      at_app_log_ingest_control.max_entry_age%type;
   l_max_file_size      at_app_log_ingest_control.max_file_size%type;
   l_ingest_sub_dirs    varchar2(1);
   l_delete_empty_files varchar2(1);
   l_fail_if_exists     boolean;
   l_exists             boolean;
   l_log_dir_code       integer;
   l_count              integer;
 begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_dir is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_DIR');
   end if;
   l_ingest_sub_dirs    := case cwms_util.is_true(nvl(p_ingest_sub_dirs, 'F')) when true then 'T' else 'F' end;
   l_delete_empty_files := case cwms_util.is_true(nvl(p_delete_empty_files, 'T')) when true then 'T' else 'F' end;
   l_fail_if_exists     := cwms_util.is_true(nvl(p_fail_if_exists, 'T'));
   l_log_file_mask := nvl(p_log_file_mask, '*');
   l_max_entry_age := nvl(p_max_entry_age, 'P1M');
   l_max_file_size := nvl(p_max_file_size, 50  * 1024 * 1024);
   l_host_fqdn := lower(p_host_fqdn);
   --------------------------
   -- get the log dir code --
   --------------------------
   store_app_log_dir(l_host_fqdn, p_log_dir, 'F', p_office_id); -- will roll back on error
   select log_dir_code
     into l_log_dir_code
     from at_app_log_dir
    where host_fqdn = l_host_fqdn
      and log_dir_name = p_log_dir
      and office_code = cwms_util.get_db_office_code(p_office_id);
   select count(*)
     into l_count
     from at_app_log_ingest_control
    where log_dir_code = l_log_dir_code
      and ingest_file_name_mask = l_log_file_mask;
   l_exists := l_count = 1;
   if l_exists then
      ----------
      -- barf --
      ----------
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Application log ingest control entry',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_dir
            || case when instr(p_log_dir, '/') > 0 then '/' else '\' end
            ||l_log_file_mask);
      else
         ------------
         -- update --
         ------------
         update at_app_log_ingest_control
            set ingest_sub_dirs = l_ingest_sub_dirs,
                max_entry_age = l_max_entry_age,
                max_file_size = l_max_file_size,
                delete_empty_files = l_delete_empty_files
          where log_dir_code = l_log_dir_code
            and ingest_file_name_mask = l_log_file_mask;
      end if;
   else
      ------------
      -- insert --
      ------------
      insert
        into at_app_log_ingest_control
      values (l_log_dir_code,
              l_log_file_mask,
              l_ingest_sub_dirs,
              l_max_entry_age,
              l_max_file_size,
              l_delete_empty_files
             );
   end if;
end store_app_log_ingest_control;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_APP_LOG_INGEST_CONTROL
--------------------------------------------------------------------------------
procedure delete_app_log_ingest_control(
   p_host_fqdn     in varchar2,
   p_log_dir       in varchar2,
   p_log_file_mask in varchar2 default '*',
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null)
is
   l_rec           at_app_log_ingest_control%rowtype;
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir_name  at_app_log_dir.log_dir_name%type;
   l_log_file_name at_app_log_file.log_file_name%type;
   l_log_file_mask at_app_log_ingest_control.ingest_file_name_mask%type;
   l_office_id     cwms_office.office_id%type;
   l_delete_action varchar2(32);
   l_cursor        sys_refcursor;
 begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_dir is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_DIR');
   end if;
   l_log_file_mask := nvl(p_log_file_mask, '*');
   l_delete_action := nvl(p_delete_action, cwms_util.delete_key);
   if l_delete_action not in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be one of '''
         ||cwms_util.delete_key
         ||''', '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'''');
   end if;
   l_host_fqdn := lower(p_host_fqdn);
   -----------------------------
   -- get the existing record --
   -----------------------------
   begin
      select *
        into l_rec
        from at_app_log_ingest_control
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = p_log_dir
                                and office_code = cwms_util.get_db_office_code(p_office_id)
                            )
         and ingest_file_name_mask = p_log_file_mask;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Application log ingest control entry',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_dir
            || case when instr(p_log_dir, '/') > 0 then '/' else '\' end
            ||l_log_file_mask);
   end;
   if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      ---------------------------------------------
      -- delete matching log files from database --
      ---------------------------------------------
      l_cursor := cat_app_log_file_f(
         l_host_fqdn,
         p_log_dir
         ||case when instr(p_log_dir, '/') > 0 then '/' else '\' end
         ||l_log_file_mask,
         p_office_id);
      loop
         fetch l_cursor into l_office_id, l_host_fqdn, l_log_dir_name, l_log_file_name;
         exit when l_cursor%notfound;
         delete_app_log_text(l_host_fqdn, l_log_dir_name, cwms_util.delete_all, l_office_id);
      end loop;
   end if;
   if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      -------------------------------------
      -- delete log ingest control entry --
      -------------------------------------
      delete
        from at_app_log_ingest_control
       where log_dir_code = l_rec.log_dir_code
         and ingest_file_name_mask = p_log_file_mask;
   end if;
end delete_app_log_ingest_control;
--------------------------------------------------------------------------------
-- PROCEDURE CAT_APP_LOG_INGEST_CONTROL
--------------------------------------------------------------------------------
procedure cat_app_log_ingest_control(
   p_cat_cursor     out sys_refcursor,
   p_host_mask      in  varchar2 default '*',
   p_log_dir_mask   in  varchar2 default '*',
   p_log_file_mask  in  varchar2 default '*',
   p_file_wildcard  in  varchar2 default 'T',
   p_office_id_mask in  varchar2 default null)
is
   l_host_mask      at_app_log_dir.host_fqdn%type;
   l_log_dir_mask   at_app_log_dir.log_dir_name%type;
   l_log_file_mask  at_app_log_ingest_control.ingest_file_name_mask%type;
   l_file_wildcard  boolean;
   l_office_id_mask cwms_office.office_id%type;
begin
   l_host_mask      := lower(nvl(p_host_mask, '*'));
   l_log_dir_mask   := nvl(p_log_dir_mask, '*');
   l_log_file_mask  := nvl(p_log_file_mask, '*');
   l_file_wildcard  := cwms_util.is_true(p_file_wildcard);
   l_office_id_mask := upper(nvl(p_office_id_mask, cwms_util.user_office_id));

   if l_file_wildcard then
      open p_cat_cursor for
         select o.office_id,
                d.host_fqdn,
                d.log_dir_name,
                c.ingest_file_name_mask as log_file_mask,
                c.ingest_sub_dirs,
                c.max_entry_age,
                c.max_file_size,
                c.delete_empty_files
           from at_app_log_ingest_control c,
                at_app_log_dir d,
                cwms_office o
          where o.office_id like cwms_util.normalize_wildcards(l_office_id_mask) escape '\'
            and d.office_code = o.office_code
            and d.host_fqdn like cwms_util.normalize_wildcards(l_host_mask) escape '\'
            and d.log_dir_name like cwms_util.normalize_wildcards(l_log_dir_mask) escape '\'
            and c.log_dir_code = d.log_dir_code
            and c.ingest_file_name_mask like cwms_util.normalize_wildcards(l_log_file_mask) escape '\';
   else
      open p_cat_cursor for
         select o.office_id,
                d.host_fqdn,
                d.log_dir_name,
                c.ingest_file_name_mask as log_file_mask,
                c.ingest_sub_dirs,
                c.max_entry_age,
                c.max_file_size,
                c.delete_empty_files
           from at_app_log_ingest_control c,
                at_app_log_dir d,
                cwms_office o
          where o.office_id like cwms_util.normalize_wildcards(l_office_id_mask) escape '\'
            and d.office_code = o.office_code
            and d.host_fqdn like cwms_util.normalize_wildcards(l_host_mask) escape '\'
            and d.log_dir_name like cwms_util.normalize_wildcards(l_log_dir_mask) escape '\'
            and c.log_dir_code = d.log_dir_code
            and c.ingest_file_name_mask = l_log_file_mask;
   end if;
end cat_app_log_ingest_control;
--------------------------------------------------------------------------------
-- FUNCTION CAT_APP_LOG_INGEST_CONTROL_F
--------------------------------------------------------------------------------
function cat_app_log_ingest_control_f(
   p_host_mask      in  varchar2 default '*',
   p_log_dir_mask   in  varchar2 default '*',
   p_log_file_mask  in  varchar2 default '*',
   p_file_wildcard  in  varchar2 default 'T',
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor
is
   l_cat_cursor sys_refcursor;
begin
   cat_app_log_ingest_control(
      l_cat_cursor,
      p_host_mask,
      p_log_dir_mask,
      p_log_file_mask,
      p_file_wildcard,
      p_office_id_mask);

   return l_cat_cursor;
end cat_app_log_ingest_control_f;
--------------------------------------------------------------------------------
-- PROCEDURE STORE_APP_LOG_FILE_ENTRY
--------------------------------------------------------------------------------
procedure store_app_log_file_entry(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_offset  in integer,
   p_entry_text    in clob,
   p_office_id     in varchar2 default null)
is
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir_name  at_app_log_dir.log_dir_name%type;
   l_log_file_name at_app_log_file.log_file_name%type;
   l_length        integer;
   l_count         integer;
   l_pos           integer;
   l_file_code     integer;
   cursor c (
      l_lhost_fqdn    varchar2,
      l_log_dir_name  varchar2,
      l_log_file_name varchar2)
   is
      select log_file_code
        from at_app_log_file
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = l_log_dir_name
                            )
         and log_file_name = l_log_file_name;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   if p_start_offset is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_START_OFFSET');
   end if;
   if p_entry_text is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_ENTRY_TEXT');
   else
      l_length := dbms_lob.getlength(p_entry_text);
      if l_length = 0 then
         cwms_err.raise('ERROR', 'P_entry_text cannot be zero length');
      end if;
   end if;
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos   := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir_name  := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ---------------------------
   -- get the log file code --
   ---------------------------
   l_host_fqdn := lower(p_host_fqdn);
   open c (l_host_fqdn, l_log_dir_name, l_log_file_name);
   fetch c into l_file_code;
   close c;
   if l_file_code is null then
      store_app_log_file(l_host_fqdn, p_log_file_name, 'T', p_office_id);
      open c (l_host_fqdn, l_log_dir_name, l_log_file_name);
      fetch c into l_file_code;
      close c;
   end if;
   if l_file_code is null then
      cwms_err.raise(
         'ERROR',
         'Cannot find or create application log file '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||l_host_fqdn
         ||':'
         ||p_log_file_name);
   end if;

   select max(log_file_end_offset)
     into l_pos
     from at_app_log_entry
    where log_file_code = l_file_code
      and log_file_end_offset >= p_start_offset;

   if l_pos > p_start_offset then
      cwms_err.raise(
         'ERROR',
         'Start offset of '
         ||p_start_offset
         ||' is smaller than existing end offset of '
         ||l_pos
         ||' for application log file '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||l_host_fqdn
         ||':'
         ||p_log_file_name);
   end if;

   insert
     into at_app_log_entry
   values (l_file_code,
           systimestamp,
           p_start_offset,
           p_start_offset + l_length - 1,
           p_entry_text
          );
end store_app_log_file_entry;
--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_APP_LOG_TEXT_TIME
--------------------------------------------------------------------------------
procedure retrieve_app_log_text_time(
   p_log_file_text in out nocopy clob,
   p_start_time    in out nocopy date,
   p_end_time      in out nocopy date,
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null)
is
   l_start_time    timestamp;
   l_end_time      timestamp;
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir_name  at_app_log_dir.log_dir_name%type;
   l_log_file_name at_app_log_file.log_file_name%type;
   l_time_zone     cwms_time_zone.time_zone_name%type;
   l_count         integer;
   l_pos           integer;
   l_file_code     integer;

   cursor c (l_start_time timestamp, l_end_time timestamp) is
      select *
        from at_app_log_entry
       where log_file_code = l_file_code
         and log_entry_utc between l_start_time and l_end_time
       order by log_entry_utc;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   if p_start_time is not null and p_end_time is not null and p_start_time > p_end_time then
      cwms_err.raise('ERROR', 'P_START_TIME must not be after P_END_TIME');
   end if;
   l_time_zone := nvl(p_time_zone, 'UTC');
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos   := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir_name  := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ---------------------------
   -- get the log file code --
   ---------------------------
   l_host_fqdn := lower(p_host_fqdn);
   begin
      select log_file_code
        into l_file_code
        from at_app_log_file
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = l_log_dir_name
                            )
         and log_file_name = l_log_file_name;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM DOES NOT EXIST',
            'Application log file',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_file_name);
   end;
   l_start_time := nvl(
      cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC'),
      timestamp '1000-01-01 00:00:00');
   l_end_time := nvl(
      cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC'),
      timestamp '3000-01-01 00:00:00');
   l_pos := -1;
   --------------------------------
   -- retrieve the log file text --
   --------------------------------
   for rec in c (l_start_time, l_end_time) loop
      ----------------------
      -- update the times --
      ----------------------
      if c%rowcount = 1 then
         p_start_time := cwms_util.change_timezone(rec.log_entry_utc, 'UTC', l_time_zone);
      end if;
      p_end_time := cwms_util.change_timezone(rec.log_entry_utc, 'UTC', l_time_zone);
      ---------------------
      -- append the text --
      ---------------------
      if p_log_file_text is not null then
         if c%rowcount = 1 then
            dbms_lob.open(p_log_file_text, dbms_lob.lob_readwrite);
         end if;
         if l_pos != -1 then
            l_count := rec.log_file_start_offset - l_pos - 1;
            if l_count <> 0 then
               cwms_util.append(p_log_file_text, chr(10)||'...'||l_count||' bytes skipped...'||chr(10));
            end if;
         end if;
         cwms_util.append(p_log_file_text, rec.log_entry_text);
         l_pos := rec.log_file_end_offset;
      end if;
   end loop;
   if p_log_file_text is not null then
      dbms_lob.close(p_log_file_text);
   end if;
end retrieve_app_log_text_time;
--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_APP_LOG_TEXT_TIME_F
--------------------------------------------------------------------------------
function retrieve_app_log_text_time_f(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_time    in date default null,
   p_end_time      in date default null,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null)
   return clob
is
   l_log_file_text clob;
   l_start_time    date;
   l_end_time      date;
begin
   dbms_lob.createtemporary(l_log_file_text, true);
   l_start_time := p_start_time;
   l_end_time   := p_end_time;

   retrieve_app_log_text_time(
      l_log_file_text,
      l_start_time,
      l_end_time,
      p_host_fqdn,
      p_log_file_name,
      p_time_zone,
      p_office_id);

   return l_log_file_text;
end retrieve_app_log_text_time_f;
--------------------------------------------------------------------------------
-- PROCEDURE RETRIEVE_APP_LOG_TEXT_OFFSET
--------------------------------------------------------------------------------
procedure retrieve_app_log_text_offset(
   p_log_file_text   in out nocopy clob,
   p_start_offset    in out nocopy integer,
   p_end_offset      in out nocopy integer,
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null)
is
   type app_log_entry_tab_t is table of at_app_log_entry%rowtype;
   l_start_offset    integer;
   l_end_offset      integer;
   l_host_fqdn       at_app_log_dir.host_fqdn%type;
   l_log_dir_name    at_app_log_dir.log_dir_name%type;
   l_log_file_name   at_app_log_file.log_file_name%type;
   l_start_inclusive boolean;
   l_end_inclusive   boolean;
   l_count           integer;
   l_pos             integer;
   l_last_pos        integer;
   l_file_code       integer;
   l_recs            app_log_entry_tab_t;

   cursor c (l_start_offset integer, l_end_offset integer) is
      select *
        from at_app_log_entry
       where log_file_code = l_file_code
         and log_file_start_offset <= l_end_offset
         and log_file_end_offset >= l_start_offset
       order by log_file_start_offset;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   l_start_inclusive := cwms_util.is_true(p_start_inclusive);
   l_end_inclusive   := cwms_util.is_true(p_end_inclusive);
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos   := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir_name  := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ---------------------------
   -- get the log file code --
   ---------------------------
   l_host_fqdn := lower(p_host_fqdn);
   begin
      select log_file_code
        into l_file_code
        from at_app_log_file
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = l_log_dir_name
                            )
         and log_file_name = l_log_file_name;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM DOES NOT EXIST',
            'Application log file',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_file_name);
   end;
   l_start_offset := nvl(p_start_offset, 0);
   l_end_offset   := nvl(p_end_offset,   1e30);
   l_last_pos := -1;
   -----------------------------------
   -- retrieve the log file entries --
   -----------------------------------
   open c (l_start_offset, l_end_offset);
   fetch c bulk collect into l_recs;
   close c;
   ------------------------
   -- update the offsets --
   ------------------------
   if l_recs.count > 0 then
      p_start_offset :=
         case
         when l_start_inclusive or l_start_offset = 0 then
            l_recs(1).log_file_start_offset
         else
            greatest(l_recs(1).log_file_start_offset, l_start_offset)
         end;
      p_end_offset :=
         case
         when l_end_inclusive or l_end_offset = 1e30 then
            l_recs(l_recs.count).log_file_end_offset
         else
            least(l_recs(l_recs.count).log_file_end_offset, l_end_offset)
         end;
   else
      p_start_offset := null;
      p_end_offset   := null;
   end if;
   if p_log_file_text is not null then
      dbms_lob.open(p_log_file_text, dbms_lob.lob_readwrite);
      ------------------
      -- get the text --
      ------------------
      for i in 1..l_recs.count loop
         case
         when i = 1 then
            if l_recs.count = 1 then
               ---------------------
               -- only one record --
               ---------------------
               if not l_start_inclusive and l_start_offset > l_recs(i).log_file_start_offset then
                  cwms_util.append(
                     p_log_file_text,
                     substr(
                        l_recs(i).log_entry_text,
                        l_start_offset - l_recs(i).log_file_start_offset + 1,
                        l_end_offset - l_start_offset + 1));
               else
                  cwms_util.append(p_log_file_text, l_recs(i).log_entry_text);
               end if;
            else
               --------------------------
               -- more than one record --
               --------------------------
               if not l_start_inclusive and l_start_offset > l_recs(i).log_file_start_offset then
                  cwms_util.append(p_log_file_text, substr(l_recs(i).log_entry_text, l_start_offset - l_recs(i).log_file_start_offset + 1));
               else
                  cwms_util.append(p_log_file_text, l_recs(i).log_entry_text);
               end if;
            end if;
         when i = l_recs.count then
            if l_recs(i).log_file_start_offset - l_recs(i-1).log_file_end_offset > 1 then
               cwms_util.append(
                  p_log_file_text,
                  chr(10)
                  ||'...'
                  ||(l_recs(i).log_file_start_offset - l_recs(i-1).log_file_end_offset - 1)
                  ||' bytes missing...'
                  ||chr(10));
            end if;
            if not l_end_inclusive and l_end_offset < l_recs(i).log_file_end_offset then
               cwms_util.append(p_log_file_text, substr(l_recs(i).log_entry_text, 1, l_end_offset - l_recs(i).log_file_start_offset + 1));
            else
               cwms_util.append(p_log_file_text, l_recs(i).log_entry_text);
            end if;
         else
            if l_recs(i).log_file_start_offset - l_recs(i-1).log_file_end_offset > 1 then
               cwms_util.append(
                  p_log_file_text,
                  chr(10)
                  ||'...'
                  ||(l_recs(i).log_file_start_offset - l_recs(i-1).log_file_end_offset - 1)
                  ||' bytes missing...'
                  ||chr(10));
            end if;
            cwms_util.append(p_log_file_text, l_recs(i).log_entry_text);
         end case;
      end loop;
      dbms_lob.close(p_log_file_text);
   end if;
end retrieve_app_log_text_offset;
--------------------------------------------------------------------------------
-- FUNCTION RETRIEVE_APP_LOG_TEXT_OFFSET_F
--------------------------------------------------------------------------------
function retrieve_app_log_text_offset_f(
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_offset    in integer default null,
   p_end_offset      in integer default null,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null)
   return clob
is
   l_log_file_text clob;
   l_start_offset  integer;
   l_end_offset    integer;
begin
   dbms_lob.createtemporary(l_log_file_text, true);
   l_start_offset := p_start_offset;
   l_end_offset   := p_end_offset;

   retrieve_app_log_text_offset(
      l_log_file_text,
      l_start_offset,
      l_end_offset,
      p_host_fqdn,
      p_log_file_name,
      p_start_inclusive,
      p_end_inclusive,
      p_office_id);

   return l_log_file_text;
end retrieve_app_log_text_offset_f;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_APP_LOG_TEXT_TIME
--------------------------------------------------------------------------------
procedure delete_app_log_text_time(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_time    in date default null,
   p_end_time      in date default null,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null)
is
   l_start_time    timestamp;
   l_end_time      timestamp;
   l_host_fqdn     at_app_log_dir.host_fqdn%type;
   l_log_dir_name  at_app_log_dir.log_dir_name%type;
   l_log_file_name at_app_log_file.log_file_name%type;
   l_time_zone     cwms_time_zone.time_zone_name%type;
   l_count         integer;
   l_pos           integer;
   l_file_code     integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   if p_start_time is not null and p_end_time is not null and p_start_time > p_end_time then
      cwms_err.raise('ERROR', 'P_START_TIME must not be after P_END_TIME');
   end if;
   l_time_zone := nvl(p_time_zone, 'UTC');
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos   := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir_name  := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ---------------------------
   -- get the log file code --
   ---------------------------
   l_host_fqdn := lower(p_host_fqdn);
   begin
      select log_file_code
        into l_file_code
        from at_app_log_file
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = l_log_dir_name
                            )
         and log_file_name = l_log_file_name;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM DOES NOT EXIST',
            'Application log file',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_file_name);
   end;
   l_start_time := nvl(
      cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC'),
      timestamp '1000-01-01 00:00:00');
   l_end_time := nvl(
      cwms_util.change_timezone(p_end_time, l_time_zone, 'UTC'),
      timestamp '3000-01-01 00:00:00');
   ------------------------
   -- delete the entries --
   ------------------------
   delete
     from at_app_log_entry
    where log_file_code = l_file_code
      and log_entry_utc between l_start_time and l_end_time;
end delete_app_log_text_time;
--------------------------------------------------------------------------------
-- PROCEDURE DELETE_APP_LOG_TEXT_OFFSET
--------------------------------------------------------------------------------
procedure delete_app_log_text_offset(
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_offset    in integer default null,
   p_end_offset      in integer default null,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null)
is
   l_start_offset    integer;
   l_end_offset      integer;
   l_host_fqdn       at_app_log_dir.host_fqdn%type;
   l_log_dir_name    at_app_log_dir.log_dir_name%type;
   l_log_file_name   at_app_log_file.log_file_name%type;
   l_start_inclusive boolean;
   l_end_inclusive   boolean;
   l_count           integer;
   l_pos             integer;
   l_last_pos        integer;
   l_file_code       integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_host_fqdn is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_HOST_FQDN');
   end if;
   if p_log_file_name is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_LOG_FILE_NAME');
   end if;
   l_start_inclusive := cwms_util.is_true(p_start_inclusive);
   l_end_inclusive   := cwms_util.is_true(p_end_inclusive);
   -------------------------------------------------
   -- split the file name into dir and base names --
   -------------------------------------------------
   l_count := regexp_count(p_log_file_name, '[/\]');
   l_pos   := regexp_instr(p_log_file_name, '[/\]', 1, l_count);
   l_log_dir_name  := substr(p_log_file_name, 1, l_pos-1);
   l_log_file_name := substr(p_log_file_name, l_pos+1);
   ---------------------------
   -- get the log file code --
   ---------------------------
   l_host_fqdn := lower(p_host_fqdn);
   begin
      select log_file_code
        into l_file_code
        from at_app_log_file
       where log_dir_code = (select log_dir_code
                               from at_app_log_dir
                              where host_fqdn = l_host_fqdn
                                and log_dir_name = l_log_dir_name
                            )
         and log_file_name = l_log_file_name;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM DOES NOT EXIST',
            'Application log file',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'
            ||l_host_fqdn
            ||':'
            ||p_log_file_name);
   end;
   l_start_offset := nvl(p_start_offset, 0);
   l_end_offset   := nvl(p_end_offset,   1e30);
   l_last_pos := -1;
   ------------------------
   -- delete the entries --
   ------------------------
   if l_start_inclusive then
      if l_end_inclusive then
         --------------------------------------------
         -- start_inclusive = T, end_inclusive = T --
         --------------------------------------------
         delete
           from at_app_log_entry
          where log_file_code = l_file_code
            and log_file_start_offset <= l_end_offset
            and log_file_end_offset   >= l_start_offset;
      else
         --------------------------------------------
         -- start_inclusive = T, end_inclusive = F --
         --------------------------------------------
         delete
           from at_app_log_entry
          where log_file_code = l_file_code
            and log_file_end_offset between l_start_offset and l_end_offset;
      end if;
   elsif l_end_inclusive then
      --------------------------------------------
      -- start_inclusive = F, end_inclusive = T --
      --------------------------------------------
      delete
        from at_app_log_entry
       where log_file_code = l_file_code
         and log_file_start_offset between l_start_offset and l_end_offset;
   else
      --------------------------------------------
      -- start_inclusive = F, end_inclusive = F --
      --------------------------------------------
      delete
        from at_app_log_entry
       where log_file_code = l_file_code
         and log_file_start_offset >= l_start_offset
         and log_file_end_offset   <= l_end_offset;
   end if;

end delete_app_log_text_offset;
--------------------------------------------------------------------------------
-- PROCEDURE AUTO_DELETE_APP_LOG_TEXTS
--------------------------------------------------------------------------------
procedure auto_delete_app_log_texts
is
   type to_delete_rec_t is record (
                           ts            timestamp,
                           too_old       varchar2(1),
                           too_big       varchar2(1),
                           office_id     varchar2(16),
                           host_fqdn     at_app_log_dir.host_fqdn%type,
                           log_file_name varchar2(512));
   type to_delete_tab_t is table of to_delete_rec_t;
   l_to_delete     to_delete_tab_t;
   l_parent_dir    at_app_log_dir.log_dir_name%type;
   l_ym            yminterval_unconstrained;
   l_ds            dsinterval_unconstrained;
   l_min_date_time timestamp;
   ---------------------------------------------------------------
   -- cursor to retrieve app log entries that should be deleted --
   ---------------------------------------------------------------
   cursor c (
      l_file_code      integer,   -- references a specific app log file
      l_min_date_time  timestamp, -- oldest date/time to keep
      l_max_total_size integer)   -- max total of entry sizes to keep
   is
      select log_entry_utc,
             too_old,
             too_big,
             office_id,
             host_fqdn,
             log_file_name
        from (select log_entry_utc,
                     total, -- used only for debugging SQL
                     too_old,
                     too_big,
                     office_id,
                     host_fqdn,
                     log_file_name
                from (select log_file_code,
                             log_entry_utc,
                             --------------------------------------------------------------------
                             -- following column accumulates siz from newest to oldest entries --
                             --------------------------------------------------------------------
                             sum(siz) over (partition by log_file_code order by log_entry_utc desc) as total,
                             --------------------------------------------------------------------------
                             -- following columns are used only for logging what got deleted and why --
                             --------------------------------------------------------------------------
                             case
                                when log_entry_utc < l_min_date_time then 'T'
                                else 'F'
                                end as too_old,
                             case
                                when sum(siz) over (partition by log_file_code order by log_entry_utc desc) > l_max_total_size then 'T'
                                else 'F'
                                end as too_big,
                             office_id,
                             host_fqdn,
                             log_file_name
                        from (select ale.log_file_code,
                                     ale.log_entry_utc,
                                     ale.log_file_end_offset - ale.log_file_start_offset + 1 as siz,
                                     o.office_id,
                                     ald.host_fqdn,
                                     ald.log_dir_name
                                        ||case when instr(ald.log_dir_name, '/') > 0 then '/' else '\' end
                                        ||alf.log_file_name as log_file_name
                                from at_app_log_entry ale,
                                     at_app_log_file  alf,
                                     at_app_log_dir   ald,
                                     cwms_office      o
                               where ale.log_file_code = l_file_code
                                 and alf.log_file_code = ale.log_file_code
                                 and ald.log_dir_code  = alf.log_dir_code
                                 and o.office_code     = ald.office_code
                             )
                     )
             )
       where too_old = 'T'
          or too_big = 'T';
begin
   --------------------------------------------------------
   -- loop through all AT_APP_LOG_INGEST_CONTROL records --
   --------------------------------------------------------
   for ctl in (select * from at_app_log_ingest_control) loop
      cwms_util.duration_to_interval(l_ym, l_ds, ctl.max_entry_age);
      l_min_date_time := systimestamp - l_ym - l_ds;
      -------------------------------------------------------------------------
      -- loop through all APP_LOG_FILE records that match the control record --
      -------------------------------------------------------------------------
      for fil in (select *
                    from at_app_log_file
                   where log_dir_code = ctl.log_dir_code
                     and log_file_name like cwms_util.normalize_wildcards(ctl.ingest_file_name_mask) escape '\'
                 )
      loop
         -------------------------------------------------------------------
         -- use the cursor to collect entries for this log file to delete --
         -------------------------------------------------------------------
         open c (fil.log_file_code, l_min_date_time, ctl.max_file_size);
         fetch c bulk collect into l_to_delete;
         close c;
         ---------------------------------------------------------
         -- delete the identified entries and log each deletion --
         ---------------------------------------------------------
         for i in 1..l_to_delete.count loop
            delete
              from at_app_log_entry
             where log_file_code = fil.log_file_code
               and log_entry_utc = l_to_delete(i).ts;
            cwms_msg.log_db_message(
               p_procedure => 'auto_delete_app_log_texts',
               p_msg_level => cwms_msg.msg_level_detailed,
               p_message   => 'Deleted application log entry: too old = '
                              ||l_to_delete(i).too_old
                              ||', too big = '
                              ||l_to_delete(i).too_big
                              ||chr(10)
                              ||to_char(l_to_delete(i).ts, 'yyyy-mm-dd  hh24:mi:ss')
                              ||chr(10)
                              ||l_to_delete(i).log_file_name);
         end loop;
         commit;
      end loop;
      if ctl.ingest_sub_dirs = 'T' then
         ----------------------------------------------------------------------
         -- construct the parent directory of any sub-directories to process --
         ----------------------------------------------------------------------
         select log_dir_name
           into l_parent_dir
           from at_app_log_dir
          where log_dir_code = ctl.log_dir_code;
         l_parent_dir := l_parent_dir || case when instr(l_parent_dir, '/') > 0 then '/' else '\' end;
         --------------------------------------------------------------
         -- loop through all subdirectories of the parent directory --
         -------------------------------------------------------------
         for subdir in (select log_dir_code
                           from at_app_log_dir
                          where host_fqdn = (select host_fqdn from at_app_log_dir where log_dir_code = ctl.log_dir_code)
                            and office_code = (select office_code from at_app_log_dir where log_dir_code = ctl.log_dir_code)
                            and instr(log_dir_name, l_parent_dir) = 1
                        )
         loop
            -----------------------------------------------------------------------------------------------
            -- loop through all APP_LOG_FILE records for the sub-directory that match the control record --
            -----------------------------------------------------------------------------------------------
            for fil in (select *
                          from at_app_log_file
                         where log_dir_code = subdir.log_dir_code
                           and log_file_name like cwms_util.normalize_wildcards(ctl.ingest_file_name_mask) escape '\'
                       )
            loop
               -------------------------------------------------------------------
               -- use the cursor to collect entries for this log file to delete --
               -------------------------------------------------------------------
               open c (fil.log_file_code, l_min_date_time, ctl.max_file_size);
               fetch c bulk collect into l_to_delete;
               close c;
               ---------------------------------------------------------
               -- delete the identified entries and log each deletion --
               ---------------------------------------------------------
               for i in 1..l_to_delete.count loop
                  delete
                    from at_app_log_entry
                   where log_file_code = fil.log_file_code
                     and log_entry_utc = l_to_delete(i).ts;

                  cwms_msg.log_db_message(
                     p_procedure => 'auto_delete_app_log_texts',
                     p_msg_level => cwms_msg.msg_level_detailed,
                     p_message   => 'Deleted application log entry: too old = '
                                    ||l_to_delete(i).too_old
                                    ||', too big = '
                                    ||l_to_delete(i).too_big
                                    ||chr(10)
                                    ||to_char(l_to_delete(i).ts, 'yyyy-mm-dd  hh24:mi:ss')
                                    ||chr(10)
                                    ||l_to_delete(i).log_file_name);
               end loop;
               commit;
            end loop;
         end loop;
      end if;
   end loop;
end auto_delete_app_log_texts;

end cwms_log_ingest;
/

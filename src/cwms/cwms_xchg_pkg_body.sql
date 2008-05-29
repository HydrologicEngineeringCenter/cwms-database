create or replace package body cwms_xchg as

--------------------------------------------------------------------------------
-- PROCEDURE GET_QUEUE_NAMES
--
   procedure get_queue_names(
      p_status_queue_name   out varchar2,
      p_realtime_queue_name out varchar2,
      p_office_id           in  varchar2 default null)
   is
      l_office_id varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      p_status_queue_name   := l_office_id || '_STATUS';
      p_realtime_queue_name := l_office_id || '_REALTIME_OPS';
   end get_queue_names;
   
--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DB_DATASTORE_ID()
--
   function db_datastore_id
      return varchar2
   is
      l_db_name      v$database.name%type;
      l_datastore_id varchar2(64);
   begin
      select name into l_db_name from v$database;
      l_datastore_id := utl_inaddr.get_host_name || ':' || l_db_name;
      l_datastore_id := substr(l_datastore_id, -(least(length(l_datastore_id), 16)));
      l_datastore_id := substr(l_datastore_id, regexp_instr(l_datastore_id, '[a-zA-Z0-9]'));
      return l_datastore_id;
   end db_datastore_id;
   
--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION DSS_DATASTORE_ID(...)
--
   function dss_datastore_id(
      p_dss_filemgr_url in varchar2,
      p_dss_file_name   in varchar2)
      return varchar2
   is
      l_url_part      varchar2(256) := regexp_replace(lower(p_dss_filemgr_url), '/dssfilemanager$', '');
      l_filename_part varchar2(256) := p_dss_file_name;
      l_datastore_id  varchar2(64   );
      l_pos           pls_integer;
      l_dns_pattern   constant varchar2(256) := 
         '([a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9][.])*[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z\-][a-zA-Z0-9\-]*[a-zA-Z0-9]';
   begin
      --
      -- remove the characters [/.:] from the url
      --
      l_url_part := replace(replace(replace(l_url_part, '.', ''), ':', ''), '/', '');
      --
      -- if the url is in DNS format, just take the machine name
      --
      if regexp_instr(l_url_part, l_dns_pattern) = 1 and
         regexp_instr(l_url_part, l_dns_pattern, 1, 1, 1) = length(l_url_part) + 1 
      then
         l_pos := instr(l_url_part, '.');
         if l_pos > 0 then
            l_url_part := substr(l_url_part, l_pos-1);
         end if;
      end if;
      --
      -- remove directory info and file extension from filename
      --
      l_filename_part := regexp_substr(l_filename_part, '[^/]+$');
      l_pos := instr(l_filename_part, '.', -1);
      if l_pos > 0 and length(l_filename_part) - l_pos < 4 then
         l_filename_part := substr(l_filename_part, 1, l_pos - 1);
      end if;
      --
      -- concatenate the url and filename parts, trimming at both ends if too long
      --
      l_datastore_id := l_url_part || ':' || l_filename_part;
      while length(l_datastore_id) > 16 loop
         l_datastore_id := substr(l_datastore_id, 2);
         if length(l_datastore_id) = 16 then exit; end if;
         l_datastore_id := substr(l_datastore_id, 1, length(l_datastore_id) - 1);
      end loop;

      return l_datastore_id;
   end dss_datastore_id;
   
--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_DSS_XCHG_SET_CODE(...)
--
   function get_dss_xchg_set_code(
      p_xchg_set_id in varchar2,
      p_office_id   in varchar2 default null)
      return number
   is
      l_xchg_set_code number(10);
   begin
      select dss_xchg_set_code
        into l_xchg_set_code
        from at_dss_xchg_set
       where office_code = cwms_util.get_office_code(p_office_id)
         and upper(dss_xchg_set_id) = upper(p_xchg_set_id);

      return l_xchg_set_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_xchg_set_id,
            'HEC-DSS exchange set');
   end get_dss_xchg_set_code;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_DSS_XCHG_DIRECTION_CODE(VARCHAR2)
--
   function get_dss_xchg_direction_code(
      p_dss_xchg_direction_id varchar2)
      return number
   is
      l_dss_xchg_direction_code number;
   begin
      select dss_xchg_direction_code
        into l_dss_xchg_direction_code
        from cwms_dss_xchg_direction
       where upper(dss_xchg_direction_id) = upper(p_dss_xchg_direction_id);

   return l_dss_xchg_direction_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_dss_xchg_direction_id,
            'HEC-DSS exchange direction');

   end get_dss_xchg_direction_code;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_DSS_PARAMETER_TYPE_CODE(VARCHAR2)
--
   function get_dss_parameter_type_code(
      p_dss_parameter_type_id in varchar2)
      return number
   is
      l_dss_parameter_type_code number(10);
   begin
      select dss_parameter_type_code
        into l_dss_parameter_type_code
        from cwms_dss_parameter_type
       where dss_parameter_type_id = upper(p_dss_parameter_type_id);

      return l_dss_parameter_type_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',p_dss_parameter_type_id,'DSS parameter type');

   end get_dss_parameter_type_code;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION GET_DSS_PARAMETER_TYPE_CODE(NUMBER)
--
   function get_dss_parameter_type_code(
      p_cwms_ts_code in number)
      return number
   is
      l_dss_parameter_type_code number(10);
   begin
      if cwms_ts.get_parameter_type_code(p_cwms_ts_code) = 'Inst' then
         if cwms_ts.get_base_parameter_id(p_cwms_ts_code) = 'Precip' then
            l_dss_parameter_type_code := get_dss_parameter_type_code('INST-CUM');
         else
            l_dss_parameter_type_code := get_dss_parameter_type_code('INST-VAL');
         end if;
      else
         begin
            select dss_parameter_type_code
              into l_dss_parameter_type_code
              from cwms_dss_parameter_type
             where parameter_type_code = cwms_ts.get_parameter_type_code(p_cwms_ts_code);
         exception
            when no_data_found then
               l_dss_parameter_type_code := get_dss_parameter_type_code('INST-VAL');
         end;
      end if;

      return l_dss_parameter_type_code;

   end get_dss_parameter_type_code;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_DSS_PARAMETER_TYPE_ID(NUMBER)
--
   function get_dss_parameter_type_id(
      p_cwms_ts_code in number)
      return varchar2
   is
      l_dss_parameter_type_id varchar2(8);
   begin
      if cwms_ts.get_parameter_type_code(p_cwms_ts_code) = 'Inst' then
         if cwms_ts.get_base_parameter_id(p_cwms_ts_code) = 'Precip' then
            l_dss_parameter_type_id := 'INST-CUM';
         else
            l_dss_parameter_type_id := 'INST-VAL';
         end if;
      else
         begin
            select dss_parameter_type_id
              into l_dss_parameter_type_id
              from cwms_dss_parameter_type
             where parameter_type_code = cwms_ts.get_parameter_type_code(p_cwms_ts_code);
         exception
            when no_data_found then
               l_dss_parameter_type_id := 'INST-VAL';
         end;
      end if;

      return l_dss_parameter_type_id;

   end get_dss_parameter_type_id;

--------------------------------------------------------------------------------
-- PROCEDURE PARSE_DSS_PATHNAME(...)
--
   procedure parse_dss_pathname(
      p_a_pathname_part out varchar2,
      p_b_pathname_part out varchar2,
      p_c_pathname_part out varchar2,
      p_d_pathname_part out varchar2,
      p_e_pathname_part out varchar2,
      p_f_pathname_part out varchar2,
      p_pathname        in  varchar2)
   is
      l_parts cwms_util.str_tab_t := cwms_util.str_tab_t();
   begin
      l_parts := cwms_util.split_text(upper(cwms_util.strip(p_pathname)), '/');
      if l_parts.count != 8 or l_parts(1) is not null or l_parts(8) is not null then
         cwms_err.raise('INVALID_ITEM', p_pathname, 'HEC-DSS pathname');
      end if;
      p_a_pathname_part := l_parts(2);
      p_b_pathname_part := l_parts(3);
      p_c_pathname_part := l_parts(4);
      p_d_pathname_part := l_parts(5);
      p_e_pathname_part := l_parts(6);
      p_f_pathname_part := l_parts(7);
   end parse_dss_pathname;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_PATHNAME(...)
--
   function make_dss_pathname(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2)
      return varchar2
   is
   begin
      return '/'
         || p_a_pathname_part
         || '/'
         || p_b_pathname_part
         || '/'
         || p_c_pathname_part
         || '/'
         || p_d_pathname_part
         || '/'
         || p_e_pathname_part
         || '/'
         || p_f_pathname_part
         || '/';
   end;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_pathname          in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2
   is
      l_dss_ts_id   varchar2(512);
   begin
      l_dss_ts_id := upper(p_pathname);

      if p_parameter_type is not null then
         l_dss_ts_id := l_dss_ts_id || ';Type=' || upper(p_parameter_type);
      end if;

      if p_units is not null then
         l_dss_ts_id := l_dss_ts_id || ';Units=' || p_units;
      end if;

      if p_time_zone is not null then
         l_dss_ts_id := l_dss_ts_id || ';Time_zone=' || p_time_zone;
      end if;

      if p_tz_usage is not null then
         l_dss_ts_id := l_dss_ts_id || ';Times=' || upper(p_tz_usage);
      end if;

      return l_dss_ts_id;

   end make_dss_ts_id;

--------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION MAKE_DSS_TS_ID(...)
--
   function make_dss_ts_id(
      p_a_pathname_part   in   varchar2,
      p_b_pathname_part   in   varchar2,
      p_c_pathname_part   in   varchar2,
      p_d_pathname_part   in   varchar2,
      p_e_pathname_part   in   varchar2,
      p_f_pathname_part   in   varchar2,
      p_parameter_type    in   varchar2 default null,
      p_units             in   varchar2 default null,
      p_time_zone         in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2
   is
   begin
      return make_dss_ts_id(
         make_dss_pathname(
            p_a_pathname_part,
            p_b_pathname_part,
            p_c_pathname_part,
            p_d_pathname_part,
            p_e_pathname_part,
            p_f_pathname_part),
         p_parameter_type,
         p_units,
         p_time_zone,
         p_tz_usage);

   end make_dss_ts_id;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_FILE(...)
--
   function create_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_fail_if_exists    in   number default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
      return number
   is
      pragma autonomous_transaction;
      l_dss_file_code   number(10);
      l_office_code     varchar2(16);
      l_dss_filemgr_url varchar2(256) := regexp_replace(p_dss_filemgr_url, '/DssFileManager$', '', 1, 1, 'i');
   begin
      l_office_code := cwms_util.get_office_code(p_office_id);
      begin
         select dss_file_code
           into l_dss_file_code
           from at_dss_file
          where office_code = l_office_code
            and dss_filemgr_url = l_dss_filemgr_url
            and dss_file_name = p_dss_file_name;

         if p_fail_if_exists != cwms_util.false_num then
            rollback;
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'HEC-DSS file',
               l_dss_filemgr_url || p_dss_file_name);
         end if;
      exception
         when no_data_found then
            begin
               insert
                 into at_dss_file
               values (cwms_seq.nextval, l_office_code, l_dss_filemgr_url, p_dss_file_name)
             returning dss_file_code
                  into l_dss_file_code;
            exception
               when others then
                  rollback;
                  cwms_err.raise(
                     'ITEM_NOT_CREATED',
                     'HEC-DSS file',
                     l_dss_filemgr_url || p_dss_file_name);
            end;
      end;

      commit;
      return l_dss_file_code;
   end create_dss_file;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_FILE(...)
--
   procedure delete_dss_file(
      p_dss_file_code   in   number)
   is
   begin
      delete
        from at_dss_file
       where dss_file_code = p_dss_file_code;
   end delete_dss_file;

--------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_FILE(...)
--
   procedure delete_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_office_id         in   varchar2 default null)
   is
      l_dss_file_code   number;
      l_dss_filemgr_url varchar2(256) := regexp_replace(p_dss_filemgr_url, '/DssFileManager$', '', 1, 1, 'i');
   begin
      select dss_file_code
        into l_dss_file_code
        from at_dss_file
       where office_code = cwms_util.get_office_code(p_office_id)
         and dss_filemgr_url = l_dss_filemgr_url
         and dss_file_name = p_dss_file_name;

      delete_dss_file(l_dss_file_code);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            l_dss_filemgr_url || p_dss_file_name,
            'HEC-DSS file');
   end delete_dss_file;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_XCHG_SET(...)
--
   function create_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_start_time        in   varchar2 default null,
      p_end_time          in   varchar2 default null,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number   default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
      return number
   is
      pragma autonomous_transaction;
      l_office_code         number(10);
      l_dss_xchg_set_code   number(10)    := null;
      l_dss_file_code       number(10);
      l_description         varchar2(80);
      l_realtime_code_in    number(10)    := null;
      l_realtime_code       number(10)    := null;
      l_dss_filemgr_url     varchar2(256) := regexp_replace(p_dss_filemgr_url, '/DssFileManager$', '', 1, 1, 'i');
      l_set_dss_filemgr_url varchar2(256);
      l_dss_file_name       varchar2(255);
   begin
      l_office_code := cwms_util.get_office_code(p_office_id);

      ------------------------------------
      -- verify the specified direction --
      ------------------------------------
      if p_realtime is not null then
         begin
            select dss_xchg_direction_code
              into l_realtime_code_in
              from cwms_dss_xchg_direction
             where upper(dss_xchg_direction_id) = upper(p_realtime);
         exception
            when no_data_found then
               rollback;
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_realtime,
                  'HEC-DSS exchange direction');
         end;
      end if;

      ----------------------------------------------------
      -- determine if the specified item already exists --
      --                                                --
      -- if so, fail if p_fail_if_exists is TRUE or if  --
      -- any of the other fields don't match.           --
      ----------------------------------------------------
      begin
         select dss_xchg_set_code, dss_file_code, description,
                realtime
           into l_dss_xchg_set_code, l_dss_file_code, l_description,
                l_realtime_code
           from at_dss_xchg_set
          where office_code = l_office_code
            and dss_xchg_set_id = p_dss_xchg_set_id;

         if p_fail_if_exists != cwms_util.false_num
            or l_description != p_description
            or nvl(l_realtime_code, 0) != nvl(l_realtime_code_in, 0) then
            rollback;
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'HEC-DSS exchange set',
               p_dss_xchg_set_id);
         end if;
      exception
         when no_data_found then
            null;
      end;

      if l_dss_xchg_set_code is not null then
         ---------------------------------------
         -- continue check on matching fields --
         ---------------------------------------
         select dss_filemgr_url, dss_file_name
           into l_set_dss_filemgr_url, l_dss_file_name
           from at_dss_file
          where dss_file_code = l_dss_file_code;

         if l_set_dss_filemgr_url != l_dss_filemgr_url
            or
            l_dss_file_name != p_dss_file_name then
            rollback;
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'HEC-DSS exchange set',
               p_office_id || '/' || p_dss_xchg_set_id);
         end if;
      else
         ---------------------
         -- create the item --
         ---------------------
         l_dss_file_code := create_dss_file(
            l_dss_filemgr_url,
            p_dss_file_name,
            cwms_util.false_num,
            p_office_id);

         begin
            insert
              into at_dss_xchg_set
                   (dss_xchg_set_code, office_code, dss_file_code,    
                    dss_xchg_set_id, description,start_time,       
                    end_time, realtime, last_update)      
            values (cwms_seq.nextval, l_office_code, l_dss_file_code,
                    p_dss_xchg_set_id, p_description, p_start_time,
                    p_end_time, l_realtime_code_in, null)
         returning dss_xchg_set_code
              into l_dss_xchg_set_code;
         exception
            when others then
               rollback;
               cwms_err.raise(
                  'ITEM_NOT_CREATED',
                  'HEC-DSS exchange set',
                  p_office_id || '/' || p_dss_xchg_set_id);
         end;
      end if;

      commit;
      
      return l_dss_xchg_set_code;

   end create_dss_xchg_set;

--------------------------------------------------------------------------------
-- PROCEDURE CREATE_DSS_XCHG_SET(...)
--
   procedure create_dss_xchg_set(
      p_dss_xchg_set_code   out      number,
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
      p_start_time          in       varchar2,
      p_end_time            in       varchar2,
      p_realtime            in       varchar2 default null,
      p_fail_if_exists      in       number default cwms_util.false_num,
      p_office_id           in       varchar2 default null)
   is
   begin
      p_dss_xchg_set_code := create_dss_xchg_set(
         p_dss_xchg_set_id,
         p_description,
         p_dss_filemgr_url,
         p_dss_file_name,
         p_start_time,
         p_end_time,
         p_realtime,
         p_fail_if_exists,
         p_office_id);
   end create_dss_xchg_set;

---------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_XCHG_SET(NUMBER)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_code in number)
   is
   begin
      delete
        from at_dss_ts_xchg_map
       where dss_xchg_set_code = p_dss_xchg_set_code;

      delete
        from at_dss_xchg_set
       where dss_xchg_set_code = p_dss_xchg_set_code;
       
   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE DELETE_DSS_XCHG_SET(...)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_id in varchar2,
      p_office_id       in varchar2 default null)
   is
   begin
      delete_dss_xchg_set(get_dss_xchg_set_code(p_dss_xchg_set_id, p_office_id));
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_dss_xchg_set_id,
            'HEC-DSS exchange set');
   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE RENAME_DSS_XCHG_SET(...)
--
   procedure rename_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null)
   is                    
      l_dss_xchg_set_code number(10);
      already_exists exception;
      pragma exception_init(already_exists, -00001);
   begin  
      l_dss_xchg_set_code := get_dss_xchg_set_code(
         p_dss_xchg_set_id,
         p_office_id);
      update at_dss_xchg_set
         set dss_xchg_set_id = p_new_dss_xchg_set_id
       where dss_xchg_set_code = l_dss_xchg_set_code;
       
   exception
      when already_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'HEC-DSS exchange set',
            p_office_id || '/' || p_new_dss_xchg_set_id);
   end rename_dss_xchg_set;

-------------------------------------------------------------------------------
-- PROCEDURE DUPLICATE_DSS_XCHG_SET(...)
--
   procedure duplicate_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null)
   is
      pragma autonomous_transaction;
      l_dss_xchg_set_code number(10);
      l_table_row at_dss_xchg_set%rowtype;
      already_exists exception;
      pragma exception_init(already_exists, -00001);
   begin
      l_dss_xchg_set_code := get_dss_xchg_set_code(
         p_dss_xchg_set_id,
         p_office_id);
          
      select *
        into l_table_row
        from at_dss_xchg_set
       where dss_xchg_set_code = l_dss_xchg_set_code;

      select cwms_seq.nextval into l_table_row.dss_xchg_set_code from dual;
      l_table_row.dss_xchg_set_id   := p_new_dss_xchg_set_id;

      insert into at_dss_xchg_set values l_table_row;
      commit;
   exception
      when no_data_found then
         rollback;
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_new_dss_xchg_set_id,
            'HEC-DSS exchange set');

      when already_exists then
         rollback;
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'HEC-DSS exchange set',
            p_office_id || '/' || p_new_dss_xchg_set_id);
   end duplicate_dss_xchg_set;

--------------------------------------------------------------------------------
-- FUNCTION UPDATE_DSS_XCHG_SET(...)
--
   function update_dss_xchg_set(
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_last_update          in   timestamp,
      p_ignore_nulls         in   varchar2 default 'T',
      p_office_id            in   varchar2 default null)
      return number
   is
      pragma autonomous_transaction;
      l_update_description    boolean := upper(p_ignore_nulls) != 'T' or p_description     is not null;
      l_update_filemgr_url    boolean := upper(p_ignore_nulls) != 'T' or p_dss_filemgr_url is not null;
      l_update_file_name      boolean := upper(p_ignore_nulls) != 'T' or p_dss_file_name   is not null;
      l_update_realtime       boolean := upper(p_ignore_nulls) != 'T' or p_realtime        is not null;
      l_update_last_update    boolean := upper(p_ignore_nulls) != 'T' or p_last_update     is not null;
      l_update                boolean := false;
      l_table_row             at_dss_xchg_set%rowtype;
      l_dss_xchg_set_code     number(10);
      l_dss_filemgr_url       varchar2(256) := regexp_replace(p_dss_filemgr_url, '/DssFileManager', '', 1, 1, 'i');
   begin
      l_dss_xchg_set_code := get_dss_xchg_set_code(
                                    p_dss_xchg_set_id,
                                    p_office_id);
      --------------------------
      -- get the exchange set --
      --------------------------
      select *
        into l_table_row
        from at_dss_xchg_set
       where dss_xchg_set_code = l_dss_xchg_set_code;

      if l_update_filemgr_url or l_update_file_name then
         declare
            l_count binary_integer;
            l_dss_file_row at_dss_file%rowtype;
         begin
            select *
              into l_dss_file_row
              from at_dss_file
             where dss_file_code = l_table_row.dss_file_code;
            if l_update_filemgr_url then
               l_dss_file_row.dss_filemgr_url := l_dss_filemgr_url;
            end if;
            if l_update_file_name then
               l_dss_file_row.dss_file_name := p_dss_file_name;
            end if;
            select count(*)
              into l_count
              from at_dss_xchg_set
             where dss_file_code = l_table_row.dss_file_code
               and dss_xchg_set_code != l_table_row.dss_xchg_set_code;
            if l_count > 0 then
               -------------------------------------
               -- create a new at_dss_file_record --
               -------------------------------------
               select cwms_seq.nextval into l_dss_file_row.dss_file_code from dual;
               l_table_row.dss_file_code := l_dss_file_row.dss_file_code;
               insert into at_dss_file values l_dss_file_row;
            else
               --------------------------------------------
               -- modify the existing at_dss_file record --
               --------------------------------------------
               update at_dss_file
                  set dss_filemgr_url = l_dss_file_row.dss_filemgr_url,
                      dss_file_name   = l_dss_file_row.dss_file_name
                where dss_file_code = l_table_row.dss_file_code;
            end if;
         end;
      end if;

      if l_update_description then
         l_table_row.description := p_description;
         l_update := true;
      end if;

      if l_update_realtime then
         l_table_row.realtime := get_dss_xchg_direction_code(p_realtime);
         l_update := true;
      end if;

      if l_update_last_update then
         l_table_row.last_update := p_last_update;
         l_update := true;
      end if;

      if l_update then
         update at_dss_xchg_set
            set description = l_table_row.description,
                realtime    = l_table_row.realtime,
                last_update = l_table_row.last_update
          where dss_xchg_set_code = l_table_row.dss_xchg_set_code;
      end if;

      commit;
      return l_table_row.dss_xchg_set_code;

   exception
      when no_data_found then
         rollback;
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_dss_xchg_set_id,
            'HEC-DSS exchange set');

      when others then
         rollback;
         raise;
   end update_dss_xchg_set;

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set(...)
--
   procedure update_dss_xchg_set(
      p_dss_xchg_set_code    out  number,
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_last_update          in   timestamp,
      p_ignore_nulls         in   varchar2 default 'T',
      p_office_id            in   varchar2 default null)
   is
   begin
      p_dss_xchg_set_code := update_dss_xchg_set(
         p_dss_xchg_set_id,
         p_description,
         p_dss_filemgr_url,
         p_dss_file_name,
         p_realtime,
         p_last_update,
         p_ignore_nulls,
         p_office_id);
   end update_dss_xchg_set;

--------------------------------------------------------------------------------
-- PROCEDURE UPDATE_DSS_XCHG_SET_TIME(...)
--
   procedure update_dss_xchg_set_time(
      p_dss_xchg_set_code    in  number,
      p_last_update          in  timestamp)
   is
      l_last_update at_dss_xchg_set.last_update%type := null;
   begin
      if p_last_update is null then
         cwms_err.raise(
            'INVALID_ITEM',
            'NULL',
            'timestamp for this procedure.  Use UPDATE_DSS_XCHG_SET instead');
      else
         begin
            select last_update
              into l_last_update
              from at_dss_xchg_set
             where dss_xchg_set_code = p_dss_xchg_set_code;

            if l_last_update is not null and l_last_update >= p_last_update then
               cwms_err.raise(
                  'INVALID_ITEM',
                  to_char(p_last_update),
                  'timestamp for this exhange set because it pre-dates the existing last update time');
            end if;

            update at_dss_xchg_set
               set last_update = p_last_update
             where dss_xchg_set_code = p_dss_xchg_set_code;

         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM', 'Specfied value', 'exchange set code.');
         end;
      end if;
   end update_dss_xchg_set_time;

-------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_TS_SPEC(...)
--
   function create_dss_ts_spec(
      p_a_pathname_part      in   varchar2,
      p_b_pathname_part      in   varchar2,
      p_c_pathname_part      in   varchar2,
      p_e_pathname_part      in   varchar2,
      p_f_pathname_part      in   varchar2,
      p_dss_parameter_type   in   varchar2,
      p_units                in   varchar2,
      p_time_zone            in   varchar2,
      p_tz_usage             in   varchar2,
      p_fail_if_exists       in   number default cwms_util.false_num,
      p_office_id            in   varchar2 default null)
      return number
   is
      pragma autonomous_transaction;
      l_table_row at_dss_ts_spec%rowtype;
      l_count pls_integer;
   begin
      l_table_row.office_code              := cwms_util.get_office_code(p_office_id);
      l_table_row.a_pathname_part          := upper(p_a_pathname_part);
      l_table_row.b_pathname_part          := upper(p_b_pathname_part);
      l_table_row.c_pathname_part          := upper(p_c_pathname_part);
      l_table_row.e_pathname_part          := upper(p_e_pathname_part);
      l_table_row.f_pathname_part          := upper(p_f_pathname_part);
      l_table_row.dss_parameter_type_code  := get_dss_parameter_type_code(p_dss_parameter_type);
      l_table_row.unit_id                  := p_units;
      l_table_row.time_zone_code           := cwms_util.get_time_zone_code(p_time_zone);
      l_table_row.tz_usage_code            := cwms_util.get_tz_usage_code(p_tz_usage);
      select *
        into l_table_row
        from at_dss_ts_spec
       where office_code              = l_table_row.office_code
         and nvl(a_pathname_part,'@') = nvl(l_table_row.a_pathname_part, '@')
         and b_pathname_part          = l_table_row.b_pathname_part
         and c_pathname_part          = l_table_row.c_pathname_part
         and e_pathname_part          = l_table_row.e_pathname_part
         and nvl(f_pathname_part,'@') = nvl(l_table_row.f_pathname_part, '@')
         and dss_parameter_type_code  = l_table_row.dss_parameter_type_code
         and unit_id                  = l_table_row.unit_id
         and time_zone_code           = l_table_row.time_zone_code
         and tz_usage_code            = l_table_row.tz_usage_code;

      if p_fail_if_exists != cwms_util.false_num then
         rollback;
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            '(Fail-if-exists = ' || p_fail_if_exists || ') HEC-DSS time series specification',
            make_dss_ts_id(
               l_table_row.a_pathname_part,
               l_table_row.b_pathname_part,
               l_table_row.c_pathname_part,
               null,
               l_table_row.e_pathname_part,
               l_table_row.f_pathname_part,
               p_dss_parameter_type,
               p_units,
               p_time_zone,
               p_tz_usage));
      end if;
      
      commit;
      return l_table_row.dss_ts_code;

   exception
      when no_data_found then
         begin
            select cwms_seq.nextval into l_table_row.dss_ts_code from dual;
            insert  into at_dss_ts_spec values l_table_row;
            select * into l_table_row from at_dss_ts_spec where dss_ts_code = l_table_row.dss_ts_code;
            commit;
            return l_table_row.dss_ts_code;

         exception
            when others then
               rollback;
               cwms_err.raise(
                  'ITEM_NOT_CREATED',
                  'HEC-DSS time series specification',
                  make_dss_ts_id(
                     l_table_row.a_pathname_part,
                     l_table_row.b_pathname_part,
                     l_table_row.c_pathname_part,
                     null,
                     l_table_row.e_pathname_part,
                     l_table_row.f_pathname_part,
                     p_dss_parameter_type,
                     p_units,
                     p_time_zone,
                     p_tz_usage));
         end;
         
      when others then
         rollback;
         cwms_err.raise('ERROR', sqlerrm);

   end create_dss_ts_spec;

-------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_TS_SPEC(...)
--
   function create_dss_ts_spec(
      p_pathname             in   varchar2,
      p_dss_parameter_type   in   varchar2,
      p_units                in   varchar2,
      p_time_zone            in   varchar2,
      p_tz_usage             in   varchar2,
      p_fail_if_exists       in   number default cwms_util.false_num,
      p_office_id            in   varchar2 default null)
      return number
   is
      l_a_pathname_part varchar2(64);
      l_b_pathname_part varchar2(64);
      l_c_pathname_part varchar2(64);
      l_d_pathname_part varchar2(64);
      l_e_pathname_part varchar2(64);
      l_f_pathname_part varchar2(64);
   begin
      parse_dss_pathname(
         l_a_pathname_part,
         l_b_pathname_part,
         l_c_pathname_part,
         l_d_pathname_part,
         l_e_pathname_part,
         l_f_pathname_part,
         p_pathname);

      return create_dss_ts_spec(
         l_a_pathname_part,
         l_b_pathname_part,
         l_c_pathname_part,
         l_e_pathname_part,
         l_f_pathname_part,
         p_dss_parameter_type,
         p_units,
         p_time_zone,
         p_tz_usage,
         p_fail_if_exists,
         p_office_id);

   end create_dss_ts_spec;

--------------------------------------------------------------------------------
-- NUMBER FUNCTION CREATE_DSS_TS_XCHG_SPEC(...)
--
   function create_dss_ts_xchg_spec(
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_time_zone            in   varchar2 default null,
      p_tz_usage             in   varchar2 default null,
      p_fail_if_exists       in   number default cwms_util.false_num,
      p_office_id            in   varchar2 default null)
      return number
   is      
      pragma autonomous_transaction;
      l_office_id                  varchar2(16);
      l_cwms_ts_code               number;
      l_dss_ts_code                number;
      l_precip_code                number;
      l_inst_code                  number;
      l_cwms_parameter_code        number;
      l_cwms_parameter_type_code   number;
      l_dss_parameter_type_code    number;
      l_time_zone_code             number;
      l_tz_usage_code              number;
      l_dss_ts_xchg_code           number;
      l_dss_parameter_type_id      varchar2(16);
      l_unit_id                    varchar2(16);
      l_time_zone_id               varchar2(28);
      l_tz_usage_id                varchar2(16);
      ts_already_exists            exception;
      pragma exception_init(ts_already_exists, -20003);
   begin
      if p_office_id is null then
         l_office_id := cwms_util.user_office_id;
      else
         l_office_id := p_office_id;
      end if;
      
      cwms_ts.create_ts_code(
         l_cwms_ts_code,
         p_cwms_ts_id,
         null,
         null,
         null,
         'F',
         'T',
         'F',
         p_office_id);

      ------------------------
      -- DSS PARAMETER TYPE --
      ------------------------
      if p_dss_parameter_type is null then
         l_dss_parameter_type_code := get_dss_parameter_type_code(l_cwms_ts_code);
      else
         l_dss_parameter_type_code := get_dss_parameter_type_code(p_dss_parameter_type);
      end if;
      ---------------
      -- DSS UNITS --
      ---------------
      if p_units is null then
         l_unit_id := cwms_ts.get_db_unit_id(p_cwms_ts_id);
      else
         l_unit_id := p_units;
      end if;
      ------------------
      -- DSS TIME_ZONE --
      ------------------
      if p_time_zone is null then
         l_time_zone_code := cwms_util.get_time_zone_code('UTC');
      else
         l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone);
      end if;
      ------------------------
      -- DSS TIME_ZONE USAGE --
      ------------------------
      if p_tz_usage is null then
         l_tz_usage_code := cwms_util.get_tz_usage_code('Standard');
      else
         l_tz_usage_code := cwms_util.get_tz_usage_code(p_tz_usage);
      end if;
      ----------------------------------------------------------------------
      -- get the text identifiers back regardless of how we got the codes --
      ----------------------------------------------------------------------
      select dss_parameter_type_id
        into l_dss_parameter_type_id
        from cwms_dss_parameter_type
       where dss_parameter_type_code= l_dss_parameter_type_code;

      select time_zone_name
        into l_time_zone_id
        from cwms_time_zone
       where time_zone_code = l_time_zone_code;

      select tz_usage_id
        into l_tz_usage_id
        from cwms_tz_usage
       where tz_usage_code = l_tz_usage_code;

      -------------------------------------------------------------------------------
      -- get the code for the existing DSS ts spec or create a new on if necessary --
      -------------------------------------------------------------------------------
      l_dss_ts_code := create_dss_ts_spec(
         p_dss_pathname,
         l_dss_parameter_type_id,
         l_unit_id,
         l_time_zone_id,
         l_tz_usage_id,
         cwms_util.false_num,
         p_office_id);

      begin
         ---------------------------------------------
         -- see if the exchange spec already exists --
         ---------------------------------------------
         select dss_ts_xchg_code
           into l_dss_ts_xchg_code
           from at_dss_ts_xchg_spec
          where ts_code = l_cwms_ts_code
            and dss_ts_code = l_dss_ts_code;

         -----------------------------------
         -- it exists, fail if we need to --
         -----------------------------------
         if p_fail_if_exists != cwms_util.false_num then
            rollback;
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'HEC-DSS time series exchange specification',
               p_office_id
               || '/'
               || p_cwms_ts_id
               || '='
               ||  make_dss_ts_id(
                     p_dss_pathname,
                     l_dss_parameter_type_id,
                     l_unit_id,
                     l_time_zone_id,
                     l_tz_usage_id));
         end if;
         
      exception
         when no_data_found then
            --------------------------------
            -- create a new exchange spec --
            --------------------------------
            declare
               l_dss_ts_xchg_spec at_dss_ts_xchg_spec%rowtype;
            begin
               select cwms_seq.nextval into l_dss_ts_xchg_spec.dss_ts_xchg_code from dual;
               l_dss_ts_xchg_spec.ts_code := l_cwms_ts_code;
               l_dss_ts_xchg_spec.dss_ts_code := l_dss_ts_code;
               insert into at_dss_ts_xchg_spec values l_dss_ts_xchg_spec;
               l_dss_ts_xchg_code := l_dss_ts_xchg_spec.dss_ts_xchg_code;
            exception
               when others then
                  rollback;
                  cwms_err.raise(
                     'ITEM_NOT_CREATED',
                     'HEC-DSS time series exchange specification',
                     p_office_id
                     || '/'
                     || p_cwms_ts_id
                     || '='
                     || make_dss_ts_id(
                           p_dss_pathname,
                           l_dss_parameter_type_id,
                           l_unit_id,
                           l_time_zone_id,
                           l_tz_usage_id));
            end;
      end;
      
      commit;
      return l_dss_ts_xchg_code;
      
   end create_dss_ts_xchg_spec;

--------------------------------------------------------------------------------
-- PROCEDURE MAP_TS_IN_XCHG_SET(...)
--
   procedure map_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_time_zone            in   varchar2 default null,
      p_tz_usage             in   varchar2 default null,
      p_office_id            in   varchar2 default null)
   is
      pragma autonomous_transaction;
      l_dss_xchg_set_id  at_dss_xchg_set.dss_xchg_set_id%type;
      l_dss_ts_xchg_code number;
      l_dss_ts_xchg_map  at_dss_ts_xchg_map%rowtype;
      l_dss_ts_spec      at_dss_ts_spec%rowtype;
      l_ts_code          number;
      l_dss_ts_code      number;
      l_office_code      number;
      l_a_part           varchar2(64);
      l_b_part           varchar2(64);
      l_c_part           varchar2(64);
      l_d_part           varchar2(64);
      l_e_part           varchar2(64);
      l_f_part           varchar2(64);
   begin
      l_office_code := cwms_util.get_office_code(p_office_id);
      parse_dss_pathname(l_a_part,l_b_part,l_c_part,l_d_part,l_e_part,l_f_part,p_dss_pathname);
      --
      -- get or create the CWMS and DSS TS CODES
      --
      cwms_ts.create_ts_code(l_ts_code, p_cwms_ts_id, null, null, null, 'F', 'T', 'F', p_office_id);
      l_dss_ts_code := create_dss_ts_spec(
         p_dss_pathname,
         p_dss_parameter_type,
         p_units,
         p_time_zone,
         p_tz_usage,
         cwms_util.false_num,
         p_office_id);

      --
      -- By the time we get here, we have valid CWMS and DSS TS CODES
      --
      begin
         --
         -- See if we have an existing DSS_TS_XCHG_SPEC
         --
         select dss_ts_xchg_code
           into l_dss_ts_xchg_code
           from at_dss_ts_xchg_spec
          where ts_code = l_ts_code
            and dss_ts_code = l_dss_ts_code;
      exception
         --
         -- DSS_TS_XCHG_SPEC does not exist, create it
         --
         when no_data_found then
            declare
               l_dss_ts_xchg_spec at_dss_ts_xchg_spec%rowtype;
            begin
               select cwms_seq.nextval into l_dss_ts_xchg_spec.dss_ts_xchg_code from dual;
               l_dss_ts_xchg_spec.ts_code := l_ts_code;
               l_dss_ts_xchg_spec.dss_ts_code := l_dss_ts_code;
               insert into at_dss_ts_xchg_spec values l_dss_ts_xchg_spec;
               l_dss_ts_xchg_code := l_dss_ts_xchg_spec.dss_ts_xchg_code;
            end;
      end;

      --
      -- By the time we get here, we have valid CWMS and DSS TS CODES and a valid DSS_TS_XCHG_SPEC
      --
      begin
         --
         -- See if the desired mapping already exists
         --
         select *
           into l_dss_ts_xchg_map
           from at_dss_ts_xchg_map
          where dss_xchg_set_code = p_dss_xchg_set_code
            and dss_ts_xchg_code = l_dss_ts_xchg_code;
         
         exception
            --
            -- Desired mapping does not exist, create it.
            --
            when no_data_found then
               select cwms_seq.nextval into l_dss_ts_xchg_map.dss_ts_xchg_map_code from dual;
               l_dss_ts_xchg_map.dss_xchg_set_code := p_dss_xchg_set_code;
               l_dss_ts_xchg_map.dss_ts_xchg_code  := l_dss_ts_xchg_code;
               insert 
                 into at_dss_ts_xchg_map
               values l_dss_ts_xchg_map;
      end;

   commit;         
   end map_ts_in_xchg_set;

--------------------------------------------------------------------------------
-- PROCEDURE UNMAP_TS_IN_XCHG_SET(...)
--
   procedure unmap_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_cwms_ts_code         in   number,
      p_office_id            in   varchar2 default null)
   is
   begin
      delete 
        from at_dss_ts_xchg_map
       where dss_xchg_set_code = p_dss_xchg_set_code
         and dss_ts_xchg_code in
             (select ts_code
                from at_dss_ts_xchg_spec
               where ts_code = p_cwms_ts_code);
               
   end unmap_ts_in_xchg_set;
   
--------------------------------------------------------------------------------
-- CLOB FUNCTION GET_DSS_XCHG_SETS(...)
--
   function get_dss_xchg_sets(
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null)
      return clob
   is
      l_spc             constant varchar2(1) := chr(9);
      l_nl              constant varchar2(1) := chr(10);
      
      l_dss_filemgr_url varchar2(256);
      l_dss_file_name   varchar2(256);
      l_filemgr_id      varchar2(256);
      l_dss_xchg_set_id varchar2(256);
      l_office_code     varchar2(256);
      l_office_id_mask  varchar2(256);
      l_office_id       varchar2(256);
      l_office_name     varchar2(256);
      l_db_name         v$database.name%type;
      l_dss_filemgr_id  varchar2(256);
      l_oracle_id       varchar2(256);
      l_xml             clob;
      l_level           binary_integer := 0;
      l_indent_str      varchar2(256) := null;
      l_text            varchar2(32767) := null;
      l_parts           cwms_util.str_tab_t := cwms_util.str_tab_t();
      type assoc_ary_t is table of  varchar2(32767) index by varchar2(32767);
      l_offices         assoc_ary_t; 
      l_filemgrs        assoc_ary_t; 
      l_filemgr_ids     assoc_ary_t; 
      
      cursor xchg_set_cur is
         select dss_filemgr_url,
                dss_file_name,
                f.dss_file_code,
                office_id,
                dss_xchg_set_code,
                dss_xchg_set_id,
                description,
                start_time,
                end_time,
                realtime,
                last_update
           from at_dss_file f,
                at_dss_xchg_set xs,
                cwms_office o
          where xs.office_code in (
                select office_code
                  from cwms_office
                 where office_id like upper(l_office_id_mask) escape '\')
            and upper(dss_xchg_set_id) like upper(l_dss_xchg_set_id) escape '\'
            and f.dss_file_code = xs.dss_file_code
            and o.office_code = f.office_code
            and dss_filemgr_url like l_dss_filemgr_url escape '\'
            and dss_file_name like l_dss_file_name escape '\'
       order by office_id asc, dss_xchg_set_id asc;

      procedure write_xml(p_data varchar2) is begin
         dbms_lob.writeappend(l_xml, length(p_data), p_data);
      end;
      
      procedure writeln_xml(p_data varchar2) is begin
         write_xml(l_indent_str || p_data || l_nl);
      end;

      procedure indent is begin
         l_level := l_level + 1;
         l_indent_str := l_indent_str || l_spc;
      end;

      procedure dedent is begin
         l_level := l_level - 1;
         l_indent_str := substr(l_indent_str, 1, l_level * length(l_spc));
      end;

   begin
      l_dss_filemgr_url := cwms_util.normalize_wildcards(regexp_replace(p_dss_filemgr_url, '/DssFileManger$', '', 1, 1, 'i'));
      l_dss_file_name   := cwms_util.normalize_wildcards(p_dss_file_name);
      l_dss_xchg_set_id := cwms_util.normalize_wildcards(p_dss_xchg_set_id);
      if p_office_id is null then
         l_office_id_mask := cwms_util.user_office_id;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id);
      end if;
      
      select name into l_db_name from v$database;
      l_oracle_id := db_datastore_id;
      
      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_xml('<?xml version="1.0" encoding="UTF-8"?>');
      writeln_xml('<cwms-dataexchange-configuration');
      indent;
      writeln_xml('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
      writeln_xml('xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/dataexchangeconfiguration.xsd">');

      for set_info in xchg_set_cur loop
         for rec in (  
            select distinct office_code
              from at_dss_ts_xchg_map xm,
                   at_dss_ts_xchg_spec xs,
                   at_dss_ts_spec ts
             where xm.dss_xchg_set_code = set_info.dss_xchg_set_code
               and xs.dss_ts_xchg_code = xm.dss_ts_xchg_code
               and ts.dss_ts_code = xs.dss_ts_code)
         loop
               select office_id,
                      long_name
                 into l_office_id,
                      l_office_name
                 from cwms_office o
                where o.office_code = rec.office_code;
                l_text := l_office_id || cwms_util.field_separator || l_office_name;
                if not l_offices.exists(l_text) then
                  l_offices(l_text) := null;
                end if;
         end loop;
         l_text := ''
            || set_info.office_id
            || cwms_util.field_separator
            || set_info.dss_filemgr_url
            || set_info.dss_file_name
            || cwms_util.field_separator
            || regexp_substr(set_info.dss_filemgr_url, '[^/:]+')
            || cwms_util.field_separator
            || regexp_substr(set_info.dss_filemgr_url, '[^:]+$')
            || cwms_util.field_separator
            || set_info.dss_file_name;
         if not l_filemgrs.exists (set_info.dss_filemgr_url||set_info.dss_file_name) then
            l_filemgr_id := dss_datastore_id(set_info.dss_filemgr_url, set_info.dss_file_name);
            declare
               i pls_integer := 1;
            begin
               l_parts.extend(1);
               while l_filemgr_ids.exists(l_filemgr_id) loop
                  i := i + 1;
                  l_parts(1) := to_char(i);
                  l_filemgr_id := substr(l_filemgr_id, 1, length(l_filemgr_id) - length(l_parts(1))) || l_parts(1);
               end loop;
            end;
            l_filemgr_ids(l_filemgr_id) := '';
            l_filemgrs(l_text) := l_filemgr_id;
            l_parts.trim(1);
         end if;
      end loop;
      
      if l_offices.count = 0 then
         if instr(l_office_id_mask, '%') > 0 or instr(l_office_id_mask, '_') > 0 then
            l_text := cwms_util.user_office_id;
         else
            l_text := l_office_id_mask;
         end if;
         writeln_xml('<office id="'||l_text||'">');
         indent;
         select long_name into l_text from cwms_office where office_id = upper(l_text);
         writeln_xml('<name>'||l_text||'</name>');
         dedent;
         writeln_xml('</office>');
      else
         l_text := l_offices.first;
         loop
            exit when l_text is null;
            l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
            writeln_xml('<office id="'||l_parts(1)||'">');
            indent;
            writeln_xml('<name>'||l_parts(2)||'</name>');
            dedent;
            writeln_xml('</office>');
            l_text := l_offices.next(l_text);
         end loop;
      end if;
      
      l_filemgr_ids.delete;
      l_text := l_filemgrs.first;
      loop
         exit when l_text is null;
         l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
         l_filemgr_ids(l_parts(2)) := l_filemgrs(l_text);
         writeln_xml('<datastore>');
         indent;
         writeln_xml('<dssfilemanager id="'||l_filemgrs(l_text)||'" office-id="'||l_parts(1)||'">');
         indent;
         writeln_xml('<host>'||l_parts(3)||'</host>');
         writeln_xml('<port>'||l_parts(4)||'</port>');
         writeln_xml('<filepath>'||l_parts(5)||'</filepath>');
         dedent;
         writeln_xml('</dssfilemanager>');
         dedent;
         writeln_xml('</datastore>');
         l_text := l_filemgrs.next(l_text);
      end loop;

      writeln_xml('<datastore>');
      indent;
      writeln_xml('<oracle id="'||l_oracle_id||'">');
      indent;
      writeln_xml('<host>'||utl_inaddr.get_host_address||'</host>');
      writeln_xml('<sid>'||l_db_name||'</sid>');
      dedent;
      writeln_xml('</oracle>');
      dedent;
      writeln_xml('</datastore>');

      for set_info in xchg_set_cur loop
         l_dss_filemgr_id := set_info.dss_filemgr_url || set_info.dss_file_name;
         writeln_xml(
            '<dataexchange-set  id="'
            || set_info.dss_xchg_set_id
            || '" office-id="' || set_info.office_id || '"'
            || case nvl(set_info.realtime, -1)
                  when -1 then null
                  when  1 then ' realtime-source-id="' || l_filemgr_ids(l_dss_filemgr_id) || '"' 
                  when  2 then ' realtime-source-id="' || l_oracle_id || '"' 
               end
            || '>');
         indent;
         if set_info.start_time is not null then
            writeln_xml('<timewindow>');
            indent;
            writeln_xml('<start-time>' || set_info.start_time || '</start-time>');
            writeln_xml('<end-time>' || set_info.end_time || '</end-time>');
            dedent;
            writeln_xml('</timewindow>');
         end if;
         writeln_xml('<description>'||set_info.description||'</description>');
         writeln_xml('<datastore-ref id="'||l_oracle_id||'"/>');
         writeln_xml('<datastore-ref id="'||l_filemgr_ids(l_dss_filemgr_id)||'"/>');
         writeln_xml('<ts-mapping-set>');
         indent;
         for map_info in ( 
            select cwms_ts_id,
                   db_office_id,
                   o.office_id,
                   a_pathname_part,
                   b_pathname_part,
                   c_pathname_part,
                   e_pathname_part,
                   f_pathname_part,
                   dss_parameter_type_id,
                   dts.unit_id,
                   time_zone_name,
                   tz_usage_id
              from at_dss_ts_xchg_map xm,
                   at_dss_ts_xchg_spec xs,
                   mv_cwms_ts_id cts,
                   at_dss_ts_spec dts,
                   cwms_office o,
                   cwms_dss_parameter_type dpt,
                   cwms_time_zone tz,
                   cwms_tz_usage tzu
             where xm.dss_xchg_set_code = set_info.dss_xchg_set_code
               and xs.dss_ts_xchg_code = xm.dss_ts_xchg_code
               and cts.ts_code = xs.ts_code
               and dts.dss_ts_code = xs.dss_ts_code
               and o.office_code = dts.office_code
               and dpt.dss_parameter_type_code = dts.dss_parameter_type_code
               and tz.time_zone_code = dts.time_zone_code
               and tzu.tz_usage_code = dts.tz_usage_code
          order by cwms_ts_id asc,
                   a_pathname_part asc,
                   b_pathname_part asc,
                   c_pathname_part asc,
                   e_pathname_part asc,
                   f_pathname_part asc)
         loop
            writeln_xml('<ts-mapping>');
            indent;
            writeln_xml(
               '<cwms-timeseries datastore-id="'
               || l_oracle_id
               || '">');
            indent;
            writeln_xml(map_info.cwms_ts_id);
            dedent;
            writeln_xml('</cwms-timeseries>');
            writeln_xml(
               '<dss-timeseries datastore-id="'
               || l_filemgr_ids(l_dss_filemgr_id)
               || '" timezone="'
               || map_info.time_zone_name
               || '" tz-usage="' 
               || map_info.tz_usage_id
               || '" units="'
               || map_info.unit_id
               || '" type="'
               || map_info.dss_parameter_type_id
               || '">');
            indent;
            writeln_xml('/' 
               || map_info.a_pathname_part || '/'
               || map_info.b_pathname_part || '/'
               || map_info.c_pathname_part || '//'
               || map_info.e_pathname_part || '/'
               || map_info.f_pathname_part || '/');
            dedent;
            writeln_xml('</dss-timeseries>');
            dedent;
            writeln_xml('</ts-mapping>');
         end loop;
         dedent;
         writeln_xml('</ts-mapping-set>');
         dedent;
         writeln_xml('</dataexchange-set>');
      end loop;
      
      dedent;
      writeln_xml('</cwms-dataexchange-configuration>');
      dbms_lob.close(l_xml);
      return l_xml;
   end get_dss_xchg_sets;

--------------------------------------------------------------------------------
   procedure retrieve_dataexchange_conf(
      p_dx_config       out xchg_dataexchange_conf_t,
      p_dss_filemgr_url in  varchar2 default null,
      p_dss_file_name   in  varchar2 default null,
      p_dss_xchg_set_id in  varchar2 default null,
      p_office_id       in  varchar2 default null)
   is
      
      i                 binary_integer;
      l_dss_filemgr_url at_dss_file.dss_filemgr_url%type;
      l_dss_file_name   at_dss_file.dss_file_name%type;
      l_filemgr_id      varchar2(16);
      l_dss_xchg_set_id at_dss_xchg_set.dss_xchg_set_id%type;
      l_office_code     cwms_office.office_code%type;
      l_office_id_mask  cwms_office.office_id%type;
      l_office_id       cwms_office.office_id%type;
      l_office_name     cwms_office.long_name%type;
      l_db_name         v$database.name%type;
      l_dss_filemgr_id  varchar2(256);
      l_oracle_id       varchar2(256);
      l_text            varchar2(32767) := null;
      l_parts           cwms_util.str_tab_t;
      l_offices         xchg_office_tab_t := xchg_office_tab_t(); 
      l_datastores      xchg_datastore_tab_t := xchg_datastore_tab_t();
      l_dx_sets         xchg_dataexchange_set_tab_t := xchg_dataexchange_set_tab_t();
      l_mapping_set     xchg_ts_mapping_set_t;
      l_dss_ts          xchg_dss_timeseries_t;
      l_cwms_ts         xchg_cwms_timeseries_t;
      l_timewindow      xchg_timewindow_t;
      type vc32k_vc32k  is table of  varchar2(32767) index by varchar2(32767);
      l_offices_a       vc32k_vc32k;
      l_filemgrs_a      vc32k_vc32k; 
      l_filemgr_ids_a   vc32k_vc32k; 
      
      cursor xchg_set_cur is
         select dss_filemgr_url,
                dss_file_name,
                f.dss_file_code,
                office_id,
                dss_xchg_set_code,
                dss_xchg_set_id,
                description,
                start_time,
                end_time,
                realtime,
                last_update
           from at_dss_file f,
                at_dss_xchg_set xs,
                cwms_office o
          where xs.office_code in (
                select office_code
                  from cwms_office
                 where office_id like upper(l_office_id_mask) escape '\')
            and upper(dss_xchg_set_id) like upper(l_dss_xchg_set_id) escape '\'
            and f.dss_file_code = xs.dss_file_code
            and o.office_code = f.office_code
            and dss_filemgr_url like l_dss_filemgr_url escape '\'
            and dss_file_name like l_dss_file_name escape '\'
       order by office_id asc, dss_xchg_set_id asc;

   begin
      l_dss_filemgr_url := cwms_util.normalize_wildcards(regexp_replace(p_dss_filemgr_url, '/DssFileManager$', '', 1, 1, 'i'));
      l_dss_file_name   := cwms_util.normalize_wildcards(p_dss_file_name);
      l_dss_xchg_set_id := cwms_util.normalize_wildcards(p_dss_xchg_set_id);
      if p_office_id is null then
         l_office_id_mask := cwms_util.get_office_code;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id);
      end if;
      
      select name into l_db_name from v$database;
      l_oracle_id := db_datastore_id;

      ------------------------------------------------------------------------------------
      -- loop through matching data exchange sets collecting office and dssfilemanagers --
      ------------------------------------------------------------------------------------
      for set_info in xchg_set_cur loop
         ---------------------
         -- collect offices --
         ---------------------
         for rec in (  
            select distinct office_code
              from at_dss_ts_xchg_map xm,
                   at_dss_ts_xchg_spec xs,
                   at_dss_ts_spec ts
             where xm.dss_xchg_set_code = set_info.dss_xchg_set_code
               and xs.dss_ts_xchg_code = xm.dss_ts_xchg_code
               and ts.dss_ts_code = xs.dss_ts_code)
         loop
               select office_id,
                      long_name
                 into l_office_id,
                      l_office_name
                 from cwms_office o
                where o.office_code = rec.office_code;
                l_text := l_office_id || cwms_util.field_separator || l_office_name;
                if not l_offices_a.exists(l_text) then
                  l_offices_a(l_text) := null;
                end if;
         end loop;
         -----------------------------
         -- collect dssfilemanagers --
         -----------------------------
         l_text := ''
            || set_info.office_id
            || cwms_util.field_separator
            || set_info.dss_filemgr_url
            || set_info.dss_file_name
            || cwms_util.field_separator
            || regexp_substr(set_info.dss_filemgr_url, '[^/:]+')
            || cwms_util.field_separator
            || regexp_substr(set_info.dss_filemgr_url, '[^:]+$')
            || cwms_util.field_separator
            || set_info.dss_file_name;
         if not l_filemgrs_a.exists (set_info.dss_filemgr_url||set_info.dss_file_name) then
            l_filemgr_id := dss_datastore_id(set_info.dss_filemgr_url, set_info.dss_file_name);
            declare
               i pls_integer := 1;
            begin
               l_parts.extend(1);
               while l_filemgr_ids_a.exists(l_filemgr_id) loop
                  i := i + 1;
                  l_parts(1) := to_char(i);
                  l_filemgr_id := substr(l_filemgr_id, 1, length(l_filemgr_id) - length(l_parts(1))) || l_parts(1);
               end loop;
            end;
            l_filemgr_ids_a(l_filemgr_id) := '';
            l_filemgrs_a(l_text) := l_filemgr_id;
            l_parts.trim(1);
         end if;
      end loop;

      ------------------------------------
      -- build the offices object table --
      ------------------------------------
      l_offices.extend(l_offices_a.count);
      l_text := l_offices_a.first;
      i := 0;
      loop
         exit when l_text is null;
         i := i + 1;
         l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
         l_offices(i) := new xchg_office_t(l_parts(1), l_parts(2));
         l_text := l_offices_a.next(l_text);
      end loop;

      ---------------------------------------
      -- build the datastores object table --
      ---------------------------------------
      l_datastores.extend(l_filemgrs_a.count+1);
      l_filemgr_ids_a.delete;
      l_text := l_filemgrs_a.first;
      i := 0;
      loop
         exit when l_text is null;
         i := i + 1;
         l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
         l_filemgr_ids_a(l_parts(2)) := l_filemgrs_a(l_text);
         l_datastores(i) := new xchg_dssfilemanager_t(
            l_filemgrs_a(l_text),
            l_parts(3),
            l_parts(4),
            l_parts(5),
            null,
            l_parts(1));
         l_text := l_filemgrs_a.next(l_text);
      end loop;

      l_datastores(l_datastores.last) := new xchg_oracle_t(
         l_oracle_id,
         utl_inaddr.get_host_address(),
         l_db_name);

      -----------------------------------------------------------------------------------------
      -- loop through matching data exchange sets again building the dataexchage set objects --
      -----------------------------------------------------------------------------------------
      for set_info in xchg_set_cur loop
         l_dss_filemgr_id := set_info.dss_filemgr_url || set_info.dss_file_name;
         l_mapping_set := new xchg_ts_mapping_set_t();
         for map_info in ( 
            select cwms_ts_id,
                   db_office_id,
                   o.office_id,
                   a_pathname_part,
                   b_pathname_part,
                   c_pathname_part,
                   e_pathname_part,
                   f_pathname_part,
                   dss_parameter_type_id,
                   dts.unit_id,
                   time_zone_name,
                   tz_usage_id
              from at_dss_ts_xchg_map xm,
                   at_dss_ts_xchg_spec xs,
                   mv_cwms_ts_id cts,
                   at_dss_ts_spec dts,
                   cwms_office o,
                   cwms_dss_parameter_type dpt,
                   cwms_time_zone tz,
                   cwms_tz_usage tzu
             where xm.dss_xchg_set_code = set_info.dss_xchg_set_code
               and xs.dss_ts_xchg_code = xm.dss_ts_xchg_code
               and cts.ts_code = xs.ts_code
               and dts.dss_ts_code = xs.dss_ts_code
               and o.office_code = dts.office_code
               and dpt.dss_parameter_type_code = dts.dss_parameter_type_code
               and tz.time_zone_code = dts.time_zone_code
               and tzu.tz_usage_code = dts.tz_usage_code
          order by cwms_ts_id asc,
                   a_pathname_part asc,
                   b_pathname_part asc,
                   c_pathname_part asc,
                   e_pathname_part asc,
                   f_pathname_part asc)
         loop
            l_dss_ts := new xchg_dss_timeseries_t(
               l_filemgr_ids_a(l_dss_filemgr_id),
               '/' || map_info.a_pathname_part || '/'
                   || map_info.b_pathname_part || '/'
                   || map_info.c_pathname_part || '//'
                   || map_info.e_pathname_part || '/'
                   || map_info.f_pathname_part || '/',
               map_info.dss_parameter_type_id,
               map_info.unit_id,
               map_info.time_zone_name,
               map_info.tz_usage_id);

            l_cwms_ts := new xchg_cwms_timeseries_t(
               l_oracle_id,
               map_info.cwms_ts_id);

            l_mapping_set.add_mapping(
               new xchg_ts_mapping_t(l_dss_ts, l_cwms_ts),
               true);
            
         end loop;
         
         if set_info.start_time is null then
            l_timewindow := null;
         else
            l_timewindow := new xchg_timewindow_t(set_info.start_time, set_info.end_time);
         end if;
         l_dx_sets.extend();
         l_dx_sets(l_dx_sets.last) := new xchg_dataexchange_set_t(
            set_info.dss_xchg_set_id,
            l_filemgr_ids_a(l_dss_filemgr_id),
            l_oracle_id,
            l_mapping_set,
            true,
            set_info.description,
            case (set_info.realtime)
               when 1 then l_filemgr_ids_a(l_dss_filemgr_id)
               when 2 then l_oracle_id
               else null
            end,
            l_timewindow,
            set_info.office_id);
      end loop;

      -------------------------------------------------
      -- build the dataexchange configuration object --
      -------------------------------------------------
      p_dx_config := new xchg_cwms_dataexchange_conf_t(
         l_offices,
         l_datastores,
         l_dx_sets,
         'cwms');
      
   end;

--------------------------------------------------------------------------------
   procedure retrieve_dataexchange_conf(
      p_dx_config       in out nocopy clob,
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null)
   is
   begin
      p_dx_config := get_dss_xchg_sets(
         p_dss_filemgr_url,
         p_dss_file_name,
         p_dss_xchg_set_id,
         p_office_id);
   end;

--------------------------------------------------------------------------------
   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  xchg_dataexchange_conf_t,
      p_store_rule        in  varchar2 default 'MERGE')
   is
      --
      -- This procedure must perform commits, so isolate them from any
      -- outer-level transactions. 
      --
      pragma autonomous_transaction;
      
      type assoc_bool_vc574 is table of boolean index by varchar2(574);      -- 574 = 183 (tsid) + 391 (pathname)
      type assoc_vc512_vc16 is table of varchar2(512) index by varchar2(16); -- 512 = 256 (URL) + 256 (filename)
      type assoc_bool_vc32  is table of boolean index by varchar2(32);       -- 32 (URL) 
      
      c_dss_to_oracle           constant pls_integer := 1;
      c_oracle_to_dss           constant pls_integer := 2;
      
      l_realtime_direction      pls_integer;
      l_sets_inserted           pls_integer := 0;
      l_sets_updated            pls_integer := 0;
      l_mappings_inserted       pls_integer := 0;
      l_mappings_updated        pls_integer := 0;
      l_mappings_deleted        pls_integer := 0;
      l_store_rule              varchar2(16) := upper(nvl(p_store_rule, 'MERGE'));
      l_can_insert              boolean := false;
      l_can_update              boolean := false;
      l_can_delete              boolean := false;
      l_set_updated             boolean;
      l_new_set                 boolean;
      l_new_map                 boolean;
      i                         pls_integer;
      j                         pls_integer;
      l_ts_id                   varchar2(183);
      l_ts_code                 at_cwms_ts_spec.ts_code%type;
      l_dss_ts_code             at_dss_ts_spec.dss_ts_code%type;
      l_dss_pathname            varchar2(391);
      l_dss_time_zone_name      cwms_time_zone.time_zone_name%type;
      l_dss_time_zone_code      cwms_time_zone.time_zone_code%type;
      l_dss_tz_usage_id         cwms_tz_usage.tz_usage_id%type;
      l_dss_tz_usage_code       cwms_tz_usage.tz_usage_code%type;
      l_dss_units               at_dss_ts_spec.unit_id%type;
      l_dss_parameter_type_id   cwms_dss_parameter_type.dss_parameter_type_id%type;
      l_dss_parameter_type_code cwms_dss_parameter_type.dss_parameter_type_code%type;
      l_set_name                at_dss_xchg_set.dss_xchg_set_id%type;
      l_set_description         at_dss_xchg_set.description%type;
      l_set_office_id           cwms_office.office_id%type;
      l_set_office_code         cwms_office.office_code%type;
      l_set_realtime_source_id  varchar2(16);         
      l_office_id               cwms_office.office_id%type;
      l_oracle_id               varchar2(16);
      l_dssfilemgr_id           varchar2(16);
      l_set_url                 varchar2(32);
      l_set_filemgr             varchar2(512);
      l_text                    varchar2(32767);
      l_a_part                  varchar2(64);
      l_b_part                  varchar2(64);
      l_c_part                  varchar2(64);
      l_d_part                  varchar2(64);
      l_e_part                  varchar2(64);
      l_f_part                  varchar2(64);
      l_map_updated             boolean;
      l_xchg_set_rec            at_dss_xchg_set%rowtype;
      l_dssfilemgr_rec          at_dss_file%rowtype;
      l_dss_ts_xchg_spec_rec    at_dss_ts_xchg_spec%rowtype;
      l_dss_ts_spec_rec         at_dss_ts_spec%rowtype;
      l_specified_maps          assoc_bool_vc574;
      l_urls_affected           assoc_bool_vc32; 
      l_dx_config               xchg_dataexchange_conf_t := p_dx_config;
      l_offices                 xchg_office_tab_t;
      l_datastores              xchg_datastore_tab_t;
      l_datastore_1             varchar2(16);
      l_datastore_2             varchar2(16);
      l_start_time              varchar2(32);
      l_end_time                varchar2(32);
      l_dx_sets                 xchg_dataexchange_set_tab_t;
      l_ts_mapping_set          xchg_ts_mapping_set_t;
      l_ts_mappings             xchg_ts_mapping_tab_t;
      l_timewindow              xchg_timewindow_t;
      l_ts1                     xchg_timeseries_t;
      l_ts2                     xchg_timeseries_t;
      l_cwms_ts                 xchg_cwms_timeseries_t;
      l_dss_ts                  xchg_dss_timeseries_t;
      l_pause_handle            urowid;
      
      procedure log(p_message in varchar2)
      is
         l_log_table  boolean := false;
         l_log_output boolean := false;
      begin
         if l_log_table then
            cwms_msg.log_db_message('store_dataexchange_conf', p_message);
         end if;
         if l_log_output then
            dbms_output.put_line(p_message);
         end if;
      end;
      
      function get_dss_file_code (p_full_url in varchar2, p_office_id in varchar2) return number
      is
         l_url  at_dss_file.dss_filemgr_url%type;
         l_fn   at_dss_file.dss_file_name%type;
      begin
         l_url  := regexp_substr(l_set_filemgr, '^//[^/]+');
         l_fn   := substr(l_set_filemgr, length(l_url)+1);
         return create_dss_file(l_url,l_fn,cwms_util.false_num,l_set_office_id); 
      end get_dss_file_code;

      function get_cwms_ts_code (p_ts_id in varchar2, p_office_id in varchar2, p_create_if_necessary in boolean) return number
      is
         ----------------------------------------------------------------------------------
         -- This is a sloppy way to get an existing ts_code or null if it doesn't exist, --
         -- but there is no API to get the ts_code without going to a materialized view, --
         -- which imposes the overhead of committing and updating the view.              --
         ----------------------------------------------------------------------------------
         l_ts_code number := null;
         begin
            begin
               --------------------------------------------------
               -- create CWMS ts, failing if it already exists --
               --------------------------------------------------
               cwms_ts.create_ts_code(l_ts_code, p_ts_id, null, null, null, 'F', 'T', 'T', p_office_id);
               if not p_create_if_necessary then
                  cwms_ts.delete_ts(l_ts_id, cwms_util.delete_ts_id, l_set_office_id);
                  l_ts_code := null;
               end if;
            exception
               when others then
                  -------------------------------------------------------------
                  -- CWMS ts already exists, re-call just to get the ts_code --
                  -------------------------------------------------------------
                  cwms_ts.create_ts_code(l_ts_code, p_ts_id, null, null, null, 'F', 'T', 'F', p_office_id);
            end;
            return l_ts_code;
         end;
   begin
      l_office_id := cwms_util.user_office_id;
      if p_dx_config is null then
         rollback;
         cwms_err.raise(
            'INVALID_ITEM',
            'NULL',
            'HEC-DSS exchange set configuration');
      end if;
      if p_dx_config.get_subtype() != 'xchg_cwms_dataexchange_conf_t' then
         cwms_err.raise('ERROR', 'Parameter is not an xchg_cwms_dataexchange_conf_t object.');
      end if;
      -----------------------------
      -- validate the store rule --
      -----------------------------
      if instr('MERGE', l_store_rule) = 1 then
         l_can_insert := true;
         l_can_update := true;
      elsif instr('INSERT', l_store_rule) = 1 then
         l_can_insert := true;
      elsif instr('UPDATE', l_store_rule) = 1 then
         l_can_update := true;
      elsif instr('REPLACE', l_store_rule) = 1 then
         l_can_insert := true;
         l_can_update := true;
         l_can_delete := true;
      else
         rollback;
         cwms_err.raise(
            'INVALID_ITEM', 
            l_store_rule, 
            'HEC-DSS exhange set store rule, should be [I]nsert, [U]pdate, [R]eplace, or [M]erge');
      end if;
      -------------------------------
      -- process the exchange sets --
      -------------------------------
      l_pause_handle := cwms_util.pause_mv_refresh('cwms_v_ts_id', 'Executing CWMS_XCHG.STORE_DATAEXCHANGE_CONF');
      l_dx_config.get_offices(l_offices);
      l_dx_config.get_datastores(l_datastores);
      l_dx_config.get_dataexchange_sets(l_dx_sets);
      for i in l_dx_sets.first..l_dx_sets.last loop
         for set_once in 1..1 loop
            exit when l_dx_sets(i) is null;
            l_set_updated            := false;
            l_new_set                := false;
            l_set_name               := l_dx_sets(i).get_id();
            l_set_description        := l_dx_sets(i).get_description();
            l_set_office_id          := l_dx_sets(i).get_office_id();
            l_set_realtime_source_id := l_dx_sets(i).get_realtime_source_id();
            l_dx_sets(i).get_datastores(l_datastore_1, l_datastore_2);
            l_dx_sets(i).get_timewindow(l_timewindow);
            if l_timewindow is null then
               l_start_time := null;
               l_end_time   := null;
            else
               l_timewindow.get_times(l_start_time, l_end_time);
            end if;
            ------------------------------
            -- identify the data stores --
            ------------------------------
            l_realtime_direction := null;
            l_set_url            := null;
            l_set_filemgr        := null;
            l_oracle_id          := null;
            for j in l_datastores.first..l_datastores.last loop
               for datastore_once in 1..1 loop
                  exit when l_datastores(j) is null;
                  l_text := l_datastores(j).get_id();
                  if l_text = l_datastore_1 then
                     if l_datastores(j).get_subtype() = 'xchg_oracle_t' then
                        l_oracle_id := l_datastore_1;
                     elsif l_datastores(j).get_subtype() = 'xchg_dssfilemanager_t' then
                        l_set_filemgr := 
                           '//' 
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_host() 
                           || ':' 
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_port() 
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_filepath(); 
                     end if;
                  elsif l_text = l_datastore_2 then
                     if l_datastores(j).get_subtype() = 'xchg_oracle_t' then
                        l_oracle_id := l_datastore_2;
                     elsif l_datastores(j).get_subtype() = 'xchg_dssfilemanager_t' then
                        l_set_url := 
                           '//' 
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_host() 
                           || ':' 
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_port(); 
                        l_set_filemgr := 
                           l_set_url
                           || treat(l_datastores(j) as xchg_dssfilemanager_t).get_filepath(); 
                     end if;
                  end if;
                  if l_set_realtime_source_id is not null then
                     if l_text = l_set_realtime_source_id then
                        if l_datastores(j).get_subtype() = 'xchg_oracle_t' then
                           l_realtime_direction := c_oracle_to_dss;
                        else
                           l_realtime_direction := c_dss_to_oracle;
                        end if;
                     end if; 
                  end if; 
               end loop;
               exit when l_oracle_id is not null and l_set_filemgr is not null;
            end loop;  
            if l_oracle_id is null or l_set_filemgr is null then
               cwms_util.resume_mv_refresh(l_pause_handle);
               rollback;
               cwms_err.raise(
                  'ERROR',
                  'Data exchange set ' 
                  || l_set_name 
                  || ' must have one oracle datastore-ref element and one dssfilemanager datastore-ref element.');
            end if;
            ------------------------
            -- check the set info --
            ------------------------
            if upper(l_set_office_id) = '__LOCAL__' then
               l_set_office_id := l_office_id;
            end if;
            begin
               select office_code
                 into l_set_office_code
                 from cwms_office
                where office_id = l_set_office_id;
            exception
               when no_data_found then
                  cwms_util.resume_mv_refresh(l_pause_handle);
                  rollback;
                  cwms_err.raise(
                     'INVALID_ITEM',
                     l_set_office_id,
                     'CWMS office id');
            end;
            if l_set_office_id != l_office_id then
               rollback;
               cwms_err.raise(
                  'ERROR',
                  'Office '
                  || l_office_id
                  || ' cannot store data exchange set for office '
                  || l_set_office_id
                  || '.');
            end if;
            begin
               select *
                 into l_xchg_set_rec
                 from at_dss_xchg_set
                where dss_xchg_set_id = l_set_name
                  and office_code = l_set_office_code;
            exception
               when no_data_found then
                  if not l_can_insert then
                     exit;
                  else 
                     l_new_set := true;
                  end if;
            end;
            if l_can_update and not l_new_set then
               if l_xchg_set_rec.description != l_set_description then
                  ----------------------------
                  -- update l_urls_affected --
                  ----------------------------
                  if not l_urls_affected.exists(l_set_url) then
                     l_urls_affected(l_set_url) := true;
                  end if;
                  ----------------------------
                  -- update the description --
                  ----------------------------
                  update at_dss_xchg_set
                     set description = l_set_description
                   where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               if nvl(l_xchg_set_rec.start_time, 'NULL') != nvl(l_start_time, 'NULL')  or 
                  nvl(l_xchg_set_rec.end_time,   'NULL') != nvl(l_end_time,   'NULL')
               then
                  ----------------------------
                  -- update l_urls_affected --
                  ----------------------------
                  if not l_urls_affected.exists(l_set_url) then
                     l_urls_affected(l_set_url) := true;
                  end if;
                  ----------------------------
                  -- update the time window --
                  ----------------------------
                  update at_dss_xchg_set
                     set start_time = l_start_time,
                         end_time   = l_end_time
                   where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               if nvl(l_xchg_set_rec.realtime, -1) != nvl(l_realtime_direction, -1) then
                  ----------------------------
                  -- update l_urls_affected --
                  ----------------------------
                  if not l_urls_affected.exists(l_set_url) then
                     l_urls_affected(l_set_url) := true;
                  end if;
                  -----------------------------------
                  -- update the realtime direction --
                  -----------------------------------
                  update at_dss_xchg_set
                     set realtime = l_realtime_direction
                   where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               select *
                 into l_dssfilemgr_rec
                 from at_dss_file
                where dss_file_code = l_xchg_set_rec.dss_file_code;
               if l_dssfilemgr_rec.dss_filemgr_url || l_dssfilemgr_rec.dss_file_name != l_set_filemgr then
                  ----------------------------
                  -- update l_urls_affected --
                  ----------------------------
                  if not l_urls_affected.exists(l_set_url) then
                     l_urls_affected(l_set_url) := true;
                  end if;
                  -------------------------
                  -- update the dss file --
                  -------------------------
                  declare
                     l_code at_dss_xchg_set.dss_file_code%type;
                  begin
                     l_code := get_dss_file_code(l_set_filemgr, l_set_office_id);
                     update at_dss_xchg_set
                        set dss_file_code = l_code
                      where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  end;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               
            elsif l_can_insert and l_new_set then
               ----------------------------
               -- update l_urls_affected --
               ----------------------------
               if not l_urls_affected.exists(l_set_url) then
                  l_urls_affected(l_set_url) := true;
               end if;
               -------------------------------
               -- insert a new exchange set --
               -------------------------------
               declare
                  l_code at_dss_xchg_set.dss_file_code%type;
               begin
                  l_code := get_dss_file_code(l_set_filemgr, l_set_office_id);
                  insert  
                    into at_dss_xchg_set
                         (dss_xchg_set_code,
                          office_code,
                          dss_file_code,
                          dss_xchg_set_id,
                          description,
                          start_time,
                          end_time,
                          realtime,
                          last_update)                    
                  values (cwms_seq.nextval,
                          l_set_office_code,
                          l_code,
                          l_set_name,
                          l_set_description,
                          l_start_time,
                          l_end_time,
                          l_realtime_direction,
                          null)
                returning dss_xchg_set_code,
                          office_code,
                          dss_file_code,
                          dss_xchg_set_id,
                          description,
                          start_time,
                          end_time,
                          realtime,
                          last_update
                     into l_xchg_set_rec;
               end;
               l_sets_inserted := l_sets_inserted + 1;
            end if;
            ----------------------
            -- get the mappings --
            ----------------------
            l_dx_sets(i).get_ts_mapping_set(l_ts_mapping_set);
            if l_ts_mapping_set is null then
               exit;
            end if;
            l_ts_mapping_set.get_mappings(l_ts_mappings);
            if l_ts_mappings is null or l_ts_mappings.count = 0 then
               exit;
            end if;
            for j in 1..l_ts_mappings.count loop
               for map_once in 1..1 loop
                  l_new_map := false;
                  ------------------------------------------
                  -- get the CWMS and DSS timeseries info --
                  ------------------------------------------
                  l_ts_mappings(j).get_timeseries(l_ts1, l_ts2);
                  if l_ts1.get_subtype() = 'xchg_cwms_timeseries_t' then
                     l_cwms_ts := treat(l_ts1 as xchg_cwms_timeseries_t);
                     l_dss_ts  := treat(l_ts2 as xchg_dss_timeseries_t);
                  else
                     l_cwms_ts := treat(l_ts2 as xchg_cwms_timeseries_t);
                     l_dss_ts  := treat(l_ts1 as xchg_dss_timeseries_t);
                  end if;
                  l_ts_id        := l_cwms_ts.get_timeseries();
                  l_dss_pathname := l_dss_ts.get_timeseries();
                  if l_can_delete then
                     l_specified_maps(l_ts_id || l_dss_pathname) := true;
                  end if;
                  --------------------------
                  -- get the CWMS TS Code --
                  --------------------------
                  l_ts_code := get_cwms_ts_code(l_ts_id, l_set_office_id, p_create_if_necessary => false);
                  if l_ts_code is null then
                     if l_can_insert then
                        l_ts_code := get_cwms_ts_code(l_ts_id, l_set_office_id, p_create_if_necessary => true);
                        l_new_map := true;
                     else
                        exit;
                     end if;
                  end if;
                  --------------------------
                  -- get the DSS TS Codes --
                  --------------------------
                  parse_dss_pathname(l_a_part,l_b_part,l_c_part,l_d_part,l_e_part,l_f_part,l_dss_pathname);
                  l_dss_time_zone_name    := l_dss_ts.get_timezone();
                  l_dss_tz_usage_id       := l_dss_ts.get_tz_usage(); 
                  l_dss_units             := l_dss_ts.get_units();
                  l_dss_parameter_type_id := l_dss_ts.get_datatype();
                  begin
                     select dts.dss_ts_code
                       into l_dss_ts_code
                       from at_dss_ts_spec dts,
                            at_dss_ts_xchg_spec xspec,
                            at_dss_ts_xchg_map xmap
                      where nvl(dts.a_pathname_part, '@') = nvl(l_a_part, '@')
                        and dts.b_pathname_part = l_b_part
                        and dts.c_pathname_part = l_c_part
                        and dts.e_pathname_part = l_e_part
                        and nvl(dts.f_pathname_part, '@') = nvl(l_f_part, '@')
                        and xspec.dss_ts_code = dts.dss_ts_code
                        and xspec.ts_code = l_ts_code
                        and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                        and xmap.dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  exception
                     when no_data_found then
                        if not l_can_insert then
                           exit;
                        end if;
                        l_new_map := true;
                  end;
                  begin
                     select time_zone_code
                       into l_dss_time_zone_code
                       from cwms_time_zone
                      where upper(time_zone_name) = upper(l_dss_time_zone_name);
                  exception
                     when no_data_found then
                        cwms_util.resume_mv_refresh(l_pause_handle);
                        rollback;
                        cwms_err.raise(
                           'INVALID_ITEM',
                           l_dss_time_zone_name,
                           'CWMS time zone identifier');
                  end;
                  begin
                     select tz_usage_code
                       into l_dss_tz_usage_code
                       from cwms_tz_usage
                      where upper(tz_usage_id) = upper(l_dss_tz_usage_id);
                  exception
                     when no_data_found then
                        cwms_util.resume_mv_refresh(l_pause_handle);
                        rollback;
                        cwms_err.raise(
                           'INVALID_ITEM',
                           l_dss_tz_usage_id,
                           'CWMS time zone usage identifier');
                  end;
                  begin
                     select dss_parameter_type_code
                       into l_dss_parameter_type_code
                       from cwms_dss_parameter_type
                      where upper(dss_parameter_type_id) = upper(l_dss_parameter_type_id);
                  exception
                     when no_data_found then
                        cwms_util.resume_mv_refresh(l_pause_handle);
                        rollback;
                        cwms_err.raise(
                           'INVALID_ITEM',
                           l_dss_parameter_type_id,
                           'HEC-DSS parameter type identifier');
                  end;
                  begin
                     if l_new_map then
                        if l_can_insert then
                           ----------------------------
                           -- update l_urls_affected --
                           ----------------------------
                           if not l_urls_affected.exists(l_set_url) then
                              l_urls_affected(l_set_url) := true;
                           end if;
                           ------------------------
                           -- insert the mapping --
                           ------------------------
                           map_ts_in_xchg_set(
                              l_xchg_set_rec.dss_xchg_set_code,
                              l_ts_id,
                              l_dss_pathname,
                              l_dss_parameter_type_id,
                              l_dss_units,
                              l_dss_time_zone_name,
                              l_dss_tz_usage_id,
                              l_set_office_id);
                           l_mappings_inserted := l_mappings_inserted + 1;
                        end if;
                     else
                        l_map_updated := false;
                        if l_can_update then
                           -------------------------------------
                           -- update the mapping if necessary --
                           -------------------------------------
                           select *
                             into l_dss_ts_spec_rec
                             from at_dss_ts_spec
                            where dss_ts_code = l_dss_ts_code;
                           if l_dss_ts_spec_rec.dss_parameter_type_code != l_dss_parameter_type_code then
                              l_dss_ts_spec_rec.dss_parameter_type_code := l_dss_parameter_type_code;
                              l_map_updated := true;
                           end if;
                           if l_dss_ts_spec_rec.unit_id != l_dss_units then
                              l_dss_ts_spec_rec.unit_id := l_dss_units;
                              l_map_updated := true;
                           end if;
                           if l_dss_ts_spec_rec.time_zone_code != l_dss_time_zone_code then
                              l_dss_ts_spec_rec.time_zone_code := l_dss_time_zone_code;
                              l_map_updated := true;
                           end if;
                           if l_dss_ts_spec_rec.tz_usage_code != l_dss_tz_usage_code then
                              l_dss_ts_spec_rec.tz_usage_code := l_dss_tz_usage_code;
                              l_map_updated := true;
                           end if;
                           if l_map_updated then
                              ----------------------------
                              -- update l_urls_affected --
                              ----------------------------
                              if not l_urls_affected.exists(l_set_url) then
                                 l_urls_affected(l_set_url) := true;
                              end if;
                              update at_dss_ts_spec
                                 set row = l_dss_ts_spec_rec
                               where dss_ts_code = l_dss_ts_spec_rec.dss_ts_code;
                              l_mappings_updated := l_mappings_updated + 1;
                           end if;
                        end if;
                     end if;
                  end;
               end loop;
            end loop;
            if l_can_delete then
               -------------------------------------------------------
               -- delete mappings that are not specified in the XML --
               -------------------------------------------------------
               for rec in (select cwms_ts_id,
                                  a_pathname_part,
                                  b_pathname_part,
                                  c_pathname_part,
                                  e_pathname_part,
                                  f_pathname_part,
                                  dss_ts_xchg_map_code
                             from mv_cwms_ts_id cts,
                                  at_dss_ts_spec dts,
                                  at_dss_ts_xchg_spec xspec,
                                  at_dss_ts_xchg_map xmap
                            where xmap.dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code
                              and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                              and cts.ts_code = xspec.ts_code
                              and dts.dss_ts_code = xspec.dss_ts_code)
               loop
                  l_text := rec.cwms_ts_id || '/'
                     || rec.a_pathname_part || '/'
                     || rec.b_pathname_part || '/'
                     || rec.c_pathname_part || '//'
                     || rec.e_pathname_part || '/'
                     || rec.f_pathname_part || '/';
                  if not l_specified_maps.exists(l_text) then
                     ----------------------------
                     -- update l_urls_affected --
                     ----------------------------
                     if not l_urls_affected.exists(l_set_url) then
                        l_urls_affected(l_set_url) := true;
                     end if;
                     delete
                       from at_dss_ts_xchg_map
                      where dss_ts_xchg_map_code = rec.dss_ts_xchg_map_code;
                     l_mappings_deleted := l_mappings_deleted + 1;
                  end if;
               end loop;
               l_specified_maps.delete;
            end if;
         end loop;
      end loop;
      cwms_util.resume_mv_refresh(l_pause_handle);

      -----------------------------------------------------------------
      -- clean up any unused data exchage info for specified offices --
      -----------------------------------------------------------------
      for i in 1..l_offices.count loop
         del_unused_dss_xchg_info(l_offices(i).get_id());
      end loop;
         
      p_sets_inserted     := l_sets_inserted;
      p_sets_updated      := l_sets_updated;
      p_mappings_inserted := l_mappings_inserted;
      p_mappings_updated  := l_mappings_updated;
      p_mappings_deleted  := l_mappings_deleted;
      
      -------------------------------------------------------------
      -- notify listeners that the configuation has been updated --
      -------------------------------------------------------------
      if l_urls_affected.count > 0 then
         l_text := '';
         l_set_url := l_urls_affected.first;
         while l_set_url is not null loop
            l_text := l_text || ',' || l_set_url || '/DssFileManager';
            l_set_url := l_urls_affected.next(l_set_url);
         end loop;
         xchg_config_updated(substr(l_text, 1));
      end if;
      
      commit;
      
   exception
      when others then
         rollback;
         raise;
   
   end store_dataexchange_conf;

--------------------------------------------------------------------------------
   procedure store_dataexchange_conf(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_dx_config         in  clob,
      p_store_rule        in  varchar2 default 'MERGE')
   is
      l_xml       xmltype;
      l_dx_config xchg_cwms_dataexchange_conf_t;
      l_start_time timestamp;
      l_end_time   timestamp;
      l_elapsed    interval day to second;
      l_dx_sets    xchg_dataexchange_set_tab_t;
      l_datastores xchg_datastore_tab_t;
      l_offices    xchg_office_tab_t;
      l_mapset     xchg_ts_mapping_set_t;
      l_maps       xchg_ts_mapping_tab_t;
      l_map_count  binary_integer := 0;
   begin
      l_start_time := systimestamp;
      l_xml := xmltype(p_dx_config);
      l_end_time := systimestamp;
      l_elapsed := l_end_time - l_start_time;
      dbms_output.put_line('Converted CLOB to XMLTYPE in ' || l_elapsed);
      l_start_time := systimestamp;
      l_dx_config := new xchg_cwms_dataexchange_conf_t(l_xml, 'dummy');
      l_end_time := systimestamp;
      l_elapsed := l_end_time - l_start_time;
      dbms_output.put_line('Converted XMLTYPE to XCHG_CWMS_DATAEXCHANGE_CONF_T in ' || l_elapsed);
      l_dx_config.get_offices(l_offices);
      dbms_output.put_line('Office count = ' || l_offices.count);
      l_dx_config.get_datastores(l_datastores);
      dbms_output.put_line('Datastore count = ' || l_datastores.count);
      l_dx_config.get_dataexchange_sets(l_dx_sets);
      dbms_output.put_line('Dataexchange set count = ' || l_dx_sets.count);
      for i in 1..l_dx_sets.count loop
         l_dx_sets(i).get_ts_mapping_set(l_mapset);
         l_mapset.get_mappings(l_maps);
         l_map_count := l_map_count + l_maps.count;
      end loop;
      dbms_output.put_line('Timeseries mapping count = ' || l_map_count);
      
      p_sets_inserted     := -1;
      p_sets_updated      := -1;
      p_mappings_inserted := -1;
      p_mappings_updated  := -1;
      p_mappings_deleted  := -1;
      
      store_dataexchange_conf(
         p_sets_inserted,
         p_sets_updated,
         p_mappings_inserted,
         p_mappings_updated,
         p_mappings_deleted,
         l_dx_config,
         p_store_rule);
      
   end;
   
--------------------------------------------------------------------------------
-- PROCEDURE PUT_DSS_XCHG_SETS(...)
--
   procedure put_dss_xchg_sets(
      p_sets_inserted     out number,
      p_sets_updated      out number,
      p_mappings_inserted out number,
      p_mappings_updated  out number,
      p_mappings_deleted  out number,
      p_xml_clob          in out nocopy clob,
      p_store_rule        in  varchar2 default 'MERGE')
   is
      type assoc_bool_vc574 is table of boolean index by varchar2(574);      -- 574 = 183 (tsid) + 391 (pathname)
      type assoc_vc512_vc16 is table of varchar2(512) index by varchar2(16); -- 512 = 256 (URL) + 256 (filename) 
      
      c_dss_to_oracle           constant pls_integer := 1;
      c_oracle_to_dss           constant pls_integer := 2;
      
      l_realtime_direction      pls_integer;
      l_sets_inserted           pls_integer := 0;
      l_sets_updated            pls_integer := 0;
      l_mappings_inserted       pls_integer := 0;
      l_mappings_updated        pls_integer := 0;
      l_mappings_deleted        pls_integer := 0;
      l_store_rule              varchar2(16) := upper(nvl(p_store_rule, 'MERGE'));
      l_can_insert              boolean := false;
      l_can_update              boolean := false;
      l_can_delete              boolean := false;
      l_set_updated             boolean;
      l_new_set                 boolean;
      l_new_map                 boolean;
      i                         pls_integer;
      j                         pls_integer;
      l_xml_document            xmltype;
      l_nodes                   xmltype;
      l_node                    xmltype;
      l_mapping_nodes           xmltype;
      l_mapping_node            xmltype;
      l_ts_id                   varchar2(183);
      l_ts_code                 at_cwms_ts_spec.ts_code%type;
      l_dss_ts_code             at_dss_ts_spec.dss_ts_code%type;
      l_dss_pathname            varchar2(391);
      l_dss_time_zone_name      cwms_time_zone.time_zone_name%type;
      l_dss_time_zone_code      cwms_time_zone.time_zone_code%type;
      l_dss_tz_usage_id         cwms_tz_usage.tz_usage_id%type;
      l_dss_tz_usage_code       cwms_tz_usage.tz_usage_code%type;
      l_dss_units               at_dss_ts_spec.unit_id%type;
      l_dss_parameter_type_id   cwms_dss_parameter_type.dss_parameter_type_id%type;
      l_dss_parameter_type_code cwms_dss_parameter_type.dss_parameter_type_code%type;
      l_set_name                at_dss_xchg_set.dss_xchg_set_id%type;
      l_set_description         at_dss_xchg_set.description%type;
      l_set_office_id           cwms_office.office_id%type;
      l_set_office_code         cwms_office.office_code%type;
      l_oracle_id               varchar2(16);
      l_dssfilemgr_id           varchar2(16);
      l_set_filemgr             varchar2(512);
      l_text                    varchar2(32767);
      l_a_part                  varchar2(64);
      l_b_part                  varchar2(64);
      l_c_part                  varchar2(64);
      l_d_part                  varchar2(64);
      l_e_part                  varchar2(64);
      l_f_part                  varchar2(64);
      l_map_updated             boolean;
      l_time1                   timestamp;
      l_time2                   timestamp;
      l_elapsed                 interval day to second;
      l_xchg_set_rec            at_dss_xchg_set%rowtype;
      l_dssfilemgr_rec          at_dss_file%rowtype;
      l_dss_ts_xchg_spec_rec    at_dss_ts_xchg_spec%rowtype;
      l_dss_ts_spec_rec         at_dss_ts_spec%rowtype;
      l_specified_maps          assoc_bool_vc574;
      l_offices                 assoc_bool_vc574;
      l_databases               assoc_bool_vc574;
      l_dssfilemgrs             assoc_vc512_vc16;
      
      function get_dss_file_code (p_full_url in varchar2, p_office_id in varchar2) return number
      is
         l_url  at_dss_file.dss_filemgr_url%type;
         l_fn   at_dss_file.dss_file_name%type;
      begin
         l_url  := regexp_substr(l_set_filemgr, '^//[^/]+');
         l_fn   := substr(l_set_filemgr, length(l_url)+1);
         return create_dss_file(l_url,l_fn,cwms_util.false_num,l_set_office_id); 
      end get_dss_file_code;

      function get_cwms_ts_code (p_ts_id in varchar2, p_office_id in varchar2, p_create_if_necessary in boolean) return number
      is
         ----------------------------------------------------------------------------------
         -- This is a sloppy way to get an existing ts_code or null if it doesn't exist, --
         -- but there is no API to get the ts_code without going to a materialized view, --
         -- which imposes the overhead of committing and updating the view.              --
         ----------------------------------------------------------------------------------
         l_ts_code number := null;
      begin
         begin
            --------------------------------------------------
            -- create CWMS ts, failing if it already exists --
            --------------------------------------------------
            cwms_ts.create_ts_code(l_ts_code, p_ts_id, null, null, null, 'F', 'T', 'T', p_office_id);
            if not p_create_if_necessary then
               cwms_ts.delete_ts(l_ts_id, cwms_util.delete_ts_id, l_set_office_id);
               l_ts_code := null;
            end if;
         exception
            when others then
               -------------------------------------------------------------
               -- CWMS ts already exists, re-call just to get the ts_code --
               -------------------------------------------------------------
               cwms_ts.create_ts_code(l_ts_code, p_ts_id, null, null, null, 'F', 'T', 'F', p_office_id);
         end;
         return l_ts_code;
      end;
      
   begin
      -----------------------------
      -- validate the store rule --
      -----------------------------
      if instr('MERGE', l_store_rule) = 1 then
         l_can_insert := true;
         l_can_update := true;
      elsif instr('INSERT', l_store_rule) = 1 then
         l_can_insert := true;
      elsif instr('UPDATE', l_store_rule) = 1 then
         l_can_update := true;
      elsif instr('REPLACE', l_store_rule) = 1 then
         l_can_insert := true;
         l_can_update := true;
         l_can_delete := true;
      else
         cwms_err.raise(
            'INVALID_ITEM', 
            l_store_rule, 
            'HEC-DSS exhange set store rule, should be [I]nsert, [U]pdate, [R]eplace, or [M]erge');
      end if;
      -----------------------------
      -- parse the clob into xml --
      -----------------------------
      if p_xml_clob is null then
         cwms_err.raise(
            'INVALID_ITEM',
            'NULL',
            'HEC-DSS exchange set configuration');
      end if;
      dbms_output.put_line('XML CLOB is '||dbms_lob.getlength(p_xml_clob)||' bytes long.');
      l_time1 := systimestamp;
      l_xml_document := xmltype(p_xml_clob);
      l_time2 := systimestamp;
      l_elapsed := l_time2 - l_time1;
      dbms_output.put_line('CLOB converted to XMLType in '||l_elapsed);
      if l_xml_document.getrootelement() != 'cwms-dataexchange-configuration' then
         cwms_err.raise(
            'INVALID_ITEM',
            l_xml_document.getrootelement(),
            'XML root element for HEC-DSS data exchange configuration.');
      end if;
      ------------------------
      -- get the office ids --
      ------------------------
      l_nodes := l_xml_document.extract('/cwms-dataexchange-configuration/office[@id]');
      if l_nodes is not null then
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/@id');
            exit when l_node is null;
            l_offices(l_node.getstringval()) := true;
         end loop;
      end if;
      -----------------------------
      -- get the dssfilemanagers --
      -----------------------------
      l_nodes := l_xml_document.extract('/cwms-dataexchange-configuration/datastore/dssfilemanager[@id]');
      if l_nodes is null then
         cwms_err.raise(
            'ERROR',
            'XML instance has no dssfilemanager datastore.');
      else 
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/*');
            exit when l_node is null;
            l_dssfilemgrs(cwms_util.strip(l_nodes.extract('*['||i||']/@id').getstringval())) := 
               '//'
               || cwms_util.strip(l_node.extract('host/node()').getstringval())
               || ':'
               || l_node.extract('port/node()').getnumberval()
               || cwms_util.strip(l_node.extract('filepath/node()').getstringval());
         end loop;
      end if;
      -----------------------
      -- get the databases --
      -----------------------
      l_nodes := l_xml_document.extract('/cwms-dataexchange-configuration/datastore/oracle[@id]');
      if l_nodes is null then
         cwms_err.raise(
            'ERROR',
            'XML instance has no Oracle datastore.');
      else 
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/@id');
            exit when l_node is null;
            l_databases(l_node.getstringval()) := true;
         end loop;
      end if;
      -----------------------
      -- get the xchg sets --
      -----------------------
      l_time1 := systimestamp;
      l_nodes := l_xml_document.extract('/cwms-dataexchange-configuration/dataexchange-set');
      l_time2 := systimestamp;
      l_elapsed := l_time2 - l_time1;
      dbms_output.put_line('Exchange sets enumerated in '||l_elapsed);
      ----------------------------------
      -- check for duplicate mappings --
      ----------------------------------
      l_time1 := systimestamp;
      declare
         type pathname_map_t is table of boolean index by varchar2(391);
         type pathname_map_tab_t is table of pathname_map_t;
         type mapping_map_t is table of pathname_map_t index by varchar2(183);
         l_pathname_map_tab pathname_map_tab_t := pathname_map_tab_t();
         l_mappings mapping_map_t;
         
         procedure cleanup is
         begin
            l_mappings.delete;
            for i in 1..l_pathname_map_tab.count loop
               l_pathname_map_tab(i).delete;
            end loop;
            l_pathname_map_tab.delete;
         end cleanup;
      begin
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/*');
            exit when l_node is null;
            cleanup;
            l_set_name := cwms_util.strip(l_nodes.extract('*['||i||']/@id').getstringval());
            l_mapping_nodes := l_node.extract('ts-mapping-set/ts-mapping');
            if l_mapping_nodes is not null then
               j := 0;
               loop
                  j := j + 1;
                  l_mapping_node := l_mapping_nodes.extract('*['||j||']/*');
                  exit when l_mapping_node is null;
                  l_ts_id := cwms_util.strip(l_mapping_node.extract('cwms-timeseries/node()').getstringval());
                  l_dss_pathname := upper(cwms_util.strip(l_mapping_node.extract('dss-timeseries/node()').getstringval()));
                  if not l_mappings.exists(l_ts_id) then
                     l_pathname_map_tab.extend;
                     l_pathname_map_tab(l_pathname_map_tab.last)(l_dss_pathname) := true;
                     l_mappings(l_ts_id) := l_pathname_map_tab(l_pathname_map_tab.last);
                  elsif not l_mappings(l_ts_id).exists(l_dss_pathname) then
                     l_mappings(l_ts_id)(l_dss_pathname) := true;
                  else
                     cleanup;
                     cwms_err.raise(
                        'ITEM_ALREADY_EXISTS',
                        'Mapping of '||l_ts_id||' to '||l_dss_pathname,
                        'in exchange set '||l_set_name);
                  end if;
               end loop;
            end if;
         end loop;
         cleanup;
      end;
      l_time2 := systimestamp;
      l_elapsed := l_time2 - l_time1;
      dbms_output.put_line('Exchange sets checked for duplicates in '||l_elapsed);
      -------------------------------
      -- process the exchange sets --
      -------------------------------
      i := 0;
      <<set_loop>>
      loop
         <<set_one_pass_loop>>
         for set_once in 1..1 loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/*');
            exit set_loop when l_node is null;
            l_set_updated := false;
            l_new_set := false;
            l_set_name := cwms_util.strip(l_nodes.extract('*['||i||']/@id').getstringval());
            l_set_description := cwms_util.strip(l_node.extract('description/node()').getstringval());
            l_set_office_id := cwms_util.strip(l_nodes.extract('*['||i||']/@office-id').getstringval());
            -----------------------------------------------
            -- parse oracle and dss datastore references --
            -----------------------------------------------
            if l_nodes.existsnode('*['||i||']/datastore-ref[2]/@id') = 0 or
               l_nodes.existsnode('*['||i||']/datastore-ref[3]/@id') = 1 then
               cwms_err.raise(
                  'ERROR',
                  'Data exchange set ' 
                  || l_set_name 
                  || ' must have exactly two datastore-ref elements.');
            end if;
            l_oracle_id := null;
            l_dssfilemgr_id := null;
            if l_databases.exists(cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[1]/@id').getstringval())) then
               l_oracle_id     := cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[1]/@id').getstringval());
               l_dssfilemgr_id := cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[2]/@id').getstringval());
            elsif l_databases.exists(cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[2]/@id').getstringval())) then
               l_dssfilemgr_id := cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[1]/@id').getstringval());
               l_oracle_id     := cwms_util.strip(l_nodes.extract('*['||i||']/datastore-ref[2]/@id').getstringval());
            else
               l_oracle_id   := null;
               l_set_filemgr := null; 
            end if;
            l_set_filemgr := l_dssfilemgrs(l_dssfilemgr_id);
            if l_oracle_id is null or l_set_filemgr is null then
               cwms_err.raise(
                  'ERROR',
                  'Data exchange set ' 
                  || l_set_name 
                  || ' must have one oracle datastore-ref element and one dssfilemanager datastore-ref element.');
            end if;
            ------------------------------------------
            -- determine realtime direction, if any --
            ------------------------------------------
            if l_nodes.existsnode('*['||i||']/@realtime-source-id') = 0 then
               l_realtime_direction := null;
            else
               l_text := cwms_util.strip(l_nodes.extract('*['||i||']/@realtime-source-id').getstringval());
               if l_text = l_oracle_id then
                  l_realtime_direction := c_oracle_to_dss;
               elsif l_text = l_dssfilemgr_id then
                  l_realtime_direction := c_dss_to_oracle;
               else
                  cwms_err.raise(
                     'ERROR',
                     'Data exchange set ' 
                     || l_set_name 
                     || ' specifies realtime data source not used by set: '
                     || l_text);
               end if;
            end if;
            dbms_output.put_line('Exchange set name = '||l_set_name);
            ------------------------
            -- check the set info --
            ------------------------
            begin
               select office_code
                 into l_set_office_code
                 from cwms_office
                where office_id = l_set_office_id;
            exception
               when no_data_found then
                  cwms_err.raise(
                     'INVALID_ITEM',
                     l_set_office_id,
                     'CWMS office id');
            end;
            begin
               select *
                 into l_xchg_set_rec
                 from at_dss_xchg_set
                where dss_xchg_set_id = l_set_name
                  and office_code = l_set_office_code;
            exception
               when no_data_found then
                  if not l_can_insert then
                     exit set_one_pass_loop;
                  else 
                     l_new_set := true;
                  end if;
            end;
            
            if l_can_update and not l_new_set then
               if l_xchg_set_rec.description != l_set_description then
                  ----------------------------
                  -- update the description --
                  ----------------------------
                  dbms_output.put_line(
                     'Changing "'
                     || l_xchg_set_rec.description
                     || '" to "'
                     || l_set_description
                     || '" for set '
                     || l_set_name);
                  update at_dss_xchg_set
                     set description = l_set_description
                   where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               if nvl(l_xchg_set_rec.realtime, -1) != nvl(l_realtime_direction, -1) then
                  -----------------------------------
                  -- update the realtime direction --
                  -----------------------------------
                  dbms_output.put_line(
                     'Changing realtime direction '
                     || case l_xchg_set_rec.realtime
                           when null then 'NULL'
                           when c_oracle_to_dss then 'Oracle-to-DSS'
                           when c_dss_to_oracle then 'DSS-to-Oracle'
                        end
                     || ' to '
                     || case l_realtime_direction
                           when null then 'NULL'
                           when c_oracle_to_dss then 'Oracle-to-DSS'
                           when c_dss_to_oracle then 'DSS-to-Oracle'
                        end
                     || ' for set '
                     || l_set_name);
                  update at_dss_xchg_set
                     set realtime = l_realtime_direction
                   where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               select *
                 into l_dssfilemgr_rec
                 from at_dss_file
                where dss_file_code = l_xchg_set_rec.dss_file_code;
               if l_dssfilemgr_rec.dss_filemgr_url || l_dssfilemgr_rec.dss_file_name != l_set_filemgr then
                  -------------------------
                  -- update the dss file --
                  -------------------------
                  dbms_output.put_line(
                     'Changing "'
                     || l_dssfilemgr_rec.dss_filemgr_url 
                     || l_dssfilemgr_rec.dss_file_name
                     || '" to "'
                     || l_set_filemgr
                     || '" for set '
                     || l_set_name);
                  declare
                     l_code at_dss_xchg_set.dss_file_code%type;
                  begin
                     l_code := get_dss_file_code(l_set_filemgr, l_set_office_id);
                     update at_dss_xchg_set
                        set dss_file_code = l_code
                      where dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                  end;
                  if not l_set_updated then
                     l_set_updated := true;
                     l_sets_updated := l_sets_updated + 1;
                  end if;
               end if;
               
            elsif l_can_insert and l_new_set then
               -------------------------------
               -- insert a new exchange set --
               -------------------------------
               declare
                  l_code at_dss_xchg_set.dss_file_code%type;
               begin
                  l_code := get_dss_file_code(l_set_filemgr, l_set_office_id);
                  insert
                    into at_dss_xchg_set
                  values (cwms_seq.nextval,
                          l_set_office_code,
                          l_code,
                          l_set_name,
                          l_set_description,
                          null, 
                          null,
                          l_realtime_direction,
                          null)
                returning dss_xchg_set_code,
                          office_code,
                          dss_file_code,
                          dss_xchg_set_id,
                          description,
                          start_time,
                          end_time,
                          realtime,
                          last_update
                     into l_xchg_set_rec;
               end;
               if not l_set_updated then
                  l_set_updated := true;
                  l_sets_inserted := l_sets_inserted + 1;
               end if;
            end if;
            ----------------------
            -- get the mappings --
            ----------------------
            l_time1 := systimestamp;
            l_mapping_nodes := l_nodes.extract('*['||i||']/ts-mapping-set/ts-mapping');
            l_time2 := systimestamp;
            l_elapsed := l_time2 - l_time1;
            dbms_output.put_line('Mappings enumerated in '||l_elapsed);
            if l_mapping_nodes is null then
               dbms_output.put_line(chr(9) || '0 mappings'); 
            else
               j := 0;
               <<map_loop>>
               loop
                  <<map_one_pass_loop>>
                  for map_once in 1..1 loop
                     j := j + 1;
                     l_new_map := false;
                     -----------------------------------
                     -- parse the mapping information --
                     -----------------------------------
                     l_mapping_node := l_mapping_nodes.extract('*['||j||']/*');
                     if l_mapping_node is null then
                        dbms_output.put_line(chr(9) || (j-1) || ' mappings'); 
                     end if;
                     exit map_loop when l_mapping_node is null;
                     l_ts_id := cwms_util.strip(l_mapping_node.extract('cwms-timeseries/node()').getstringval());
                     l_dss_pathname := upper(cwms_util.strip(l_mapping_node.extract('dss-timeseries/node()').getstringval()));
                     if l_dssfilemgrs(cwms_util.strip(l_mapping_node.extract('dss-timeseries/@datastore-id').getstringval())) != 
                        l_set_filemgr then
                        cwms_err.raise(
                           'ERROR',
                           'Data exchange set ' 
                           || l_set_name 
                           || ' has inconsistent datastore for pathname '
                           || l_dss_pathname);
                     end if;
                     if l_can_delete then
                        l_specified_maps(l_ts_id || l_dss_pathname) := true;
                     end if;
                     parse_dss_pathname(l_a_part,l_b_part,l_c_part,l_d_part,l_e_part,l_f_part,l_dss_pathname);
                     l_dss_time_zone_name := cwms_util.strip(l_mapping_node.extract('dss-timeseries/@timezone').getstringval());
                     if l_mapping_node.extract('dss-timeseries/@tz-usage') is null then
                        l_dss_tz_usage_id := 'Standard';
                     else
                        l_dss_tz_usage_id := cwms_util.strip(l_mapping_node.extract('dss-timeseries/@tz-usage').getstringval());
                     end if;
                     l_dss_units := cwms_util.strip(l_mapping_node.extract('dss-timeseries/@units').getstringval());
                     l_dss_parameter_type_id := upper(cwms_util.strip(l_mapping_node.extract('dss-timeseries/@type').getstringval()));

                     l_ts_code := get_cwms_ts_code(l_ts_id, l_set_office_id, p_create_if_necessary => false);
                     if l_ts_code is null then
                        if l_can_insert then
                           l_ts_code := get_cwms_ts_code(l_ts_id, l_set_office_id, p_create_if_necessary => true);
                           l_new_map := true;
                        else
                           exit map_one_pass_loop;
                        end if;
                     end if;
                     
                     begin
                        select dts.dss_ts_code
                          into l_dss_ts_code
                          from at_dss_ts_spec dts,
                               at_dss_ts_xchg_spec xspec,
                               at_dss_ts_xchg_map xmap
                         where nvl(dts.a_pathname_part, '@') = nvl(l_a_part, '@')
                           and dts.b_pathname_part = l_b_part
                           and dts.c_pathname_part = l_c_part
                           and dts.e_pathname_part = l_e_part
                           and nvl(dts.f_pathname_part, '@') = nvl(l_f_part, '@')
                           and xspec.dss_ts_code = dts.dss_ts_code
                           and xspec.ts_code = l_ts_code
                           and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                           and xmap.dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code;
                     exception
                        when no_data_found then
                           if not l_can_insert then
                              exit map_one_pass_loop;
                           end if;
                           l_new_map := true;
                     end;
                     begin
                        select time_zone_code
                          into l_dss_time_zone_code
                          from cwms_time_zone
                         where upper(time_zone_name) = upper(l_dss_time_zone_name);
                     exception
                        when no_data_found then
                           cwms_err.raise(
                              'INVALID_ITEM',
                              l_dss_time_zone_name,
                              'CWMS time zone identifier');
                     end;
                     begin
                        select tz_usage_code
                          into l_dss_tz_usage_code
                          from cwms_tz_usage
                         where upper(tz_usage_id) = upper(l_dss_tz_usage_id);
                     exception
                        when no_data_found then
                           cwms_err.raise(
                              'INVALID_ITEM',
                              l_dss_tz_usage_id,
                              'CWMS time zone usage identifier');
                     end;
                     begin
                        select dss_parameter_type_code
                          into l_dss_parameter_type_code
                          from cwms_dss_parameter_type
                         where upper(dss_parameter_type_id) = upper(l_dss_parameter_type_id);
                     exception
                        when no_data_found then
                           cwms_err.raise(
                              'INVALID_ITEM',
                              l_dss_parameter_type_id,
                              'HEC-DSS parameter type identifier');
                     end;
                     begin
                        if l_new_map then
                           if l_can_insert then
                                 ------------------------
                                 -- insert the mapping --
                                 ------------------------
                                 map_ts_in_xchg_set(
                                    l_xchg_set_rec.dss_xchg_set_code,
                                    l_ts_id,
                                    l_dss_pathname,
                                    l_dss_parameter_type_id,
                                    l_dss_units,
                                    l_dss_time_zone_name,
                                    l_dss_tz_usage_id,
                                    l_set_office_id);
                                 l_mappings_inserted := l_mappings_inserted + 1;
                           end if;
                        else
                           l_map_updated := false;
                           if l_can_update then
                              -------------------------------------
                              -- update the mapping if necessary --
                              -------------------------------------
                              select *
                                into l_dss_ts_spec_rec
                                from at_dss_ts_spec
                               where dss_ts_code = l_dss_ts_code;
                              if l_dss_ts_spec_rec.dss_parameter_type_code != l_dss_parameter_type_code then
                                 l_dss_ts_spec_rec.dss_parameter_type_code := l_dss_parameter_type_code;
                                 l_map_updated := true;
                              end if;
                              if l_dss_ts_spec_rec.unit_id != l_dss_units then
                                 l_dss_ts_spec_rec.unit_id := l_dss_units;
                                 l_map_updated := true;
                              end if;
                              if l_dss_ts_spec_rec.time_zone_code != l_dss_time_zone_code then
                                 l_dss_ts_spec_rec.time_zone_code := l_dss_time_zone_code;
                                 l_map_updated := true;
                              end if;
                              if l_dss_ts_spec_rec.tz_usage_code != l_dss_tz_usage_code then
                                 l_dss_ts_spec_rec.tz_usage_code := l_dss_tz_usage_code;
                                 l_map_updated := true;
                              end if;
                              if l_map_updated then
                                 update at_dss_ts_spec
                                    set row = l_dss_ts_spec_rec
                                  where dss_ts_code = l_dss_ts_spec_rec.dss_ts_code;
                                 l_mappings_updated := l_mappings_updated + 1;
                              end if;
                           end if;
                        end if;
                     end;
                  end loop map_one_pass_loop;
               end loop map_loop;
            end if;
            if l_can_delete then
               -------------------------------------------------------
               -- delete mappings that are not specified in the XML --
               -------------------------------------------------------
               dbms_output.put_line(''||l_specified_maps.count||' items');
               for rec in (select cwms_ts_id,
                                  a_pathname_part,
                                  b_pathname_part,
                                  c_pathname_part,
                                  e_pathname_part,
                                  f_pathname_part,
                                  dss_ts_xchg_map_code
                             from mv_cwms_ts_id cts,
                                  at_dss_ts_spec dts,
                                  at_dss_ts_xchg_spec xspec,
                                  at_dss_ts_xchg_map xmap
                            where xmap.dss_xchg_set_code = l_xchg_set_rec.dss_xchg_set_code
                              and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                              and cts.ts_code = xspec.ts_code
                              and dts.dss_ts_code = xspec.dss_ts_code)
               loop
                  l_text := rec.cwms_ts_id || '/'
                     || rec.a_pathname_part || '/'
                     || rec.b_pathname_part || '/'
                     || rec.c_pathname_part || '//'
                     || rec.e_pathname_part || '/'
                     || rec.f_pathname_part || '/';
                  if not l_specified_maps.exists(l_text) then
                     delete
                       from at_dss_ts_xchg_map
                      where dss_ts_xchg_map_code = rec.dss_ts_xchg_map_code;
                     l_mappings_deleted := l_mappings_deleted + 1;
                  end if;
               end loop;
               l_specified_maps.delete;
            end if;
         end loop set_one_pass_loop;
      end loop set_loop;

      -----------------------------------------------------------------
      -- clean up any unused data exchage info for specified offices --
      -----------------------------------------------------------------
      l_text := l_offices.first;
      while l_text is not null loop
         del_unused_dss_xchg_info(l_text);
         l_text := l_offices.next(l_text);
      end loop;
         
      p_sets_inserted     := l_sets_inserted;
      p_sets_updated      := l_sets_updated;
      p_mappings_inserted := l_mappings_inserted;
      p_mappings_updated  := l_mappings_updated;
      p_mappings_deleted  := l_mappings_deleted;
      
   exception
      when others then
         raise;
         
   end put_dss_xchg_sets;
      
--------------------------------------------------------------------------------
-- PROCEDURE UNMAP_ALL_TS_IN_XCHG_SET(NUMBER)
--
   procedure unmap_all_ts_in_xchg_set(
      p_dss_xchg_set_code   in   number)
   is
   begin
      delete 
        from at_dss_ts_xchg_map
       where dss_xchg_set_code = p_dss_xchg_set_code;
   end;

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_FILES(VARCHAR2)
--
   procedure del_unused_dss_files(
      p_office_id in varchar2 default null)
   is
   begin
      delete 
        from at_dss_file
       where office_code = cwms_util.get_office_code(p_office_id)
         and dss_file_code not in 
               (select distinct dss_file_code from at_dss_xchg_set);
   end del_unused_dss_files;

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_TS_XCHG_SPECS
--
   procedure del_unused_dss_ts_xchg_specs
   is
   begin
      delete 
        from at_dss_ts_xchg_spec
       where dss_ts_xchg_code not in 
               (select distinct dss_ts_xchg_code from at_dss_ts_xchg_map);
   end del_unused_dss_ts_xchg_specs;

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_TS_SPECS(VARCHAR2)
--
   procedure del_unused_dss_ts_specs(
      p_office_id in varchar2 default null)                                     
   is
   begin
      delete 
       from at_dss_ts_spec
      where office_code = cwms_util.get_office_code(p_office_id)
        and dss_ts_code not in (select distinct dss_ts_code from at_dss_ts_xchg_spec);
   end del_unused_dss_ts_specs;

--------------------------------------------------------------------------------
-- PROCEDURE DEL_UNUSED_DSS_XCHG_INFO(VARCHAR2)
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null)                                     
   is
   begin
      del_unused_dss_files;
      del_unused_dss_ts_xchg_specs;
      del_unused_dss_ts_specs(p_office_id);
   end del_unused_dss_xchg_info;

-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION IS_REALTIME_EXPORT(INTEGER)
--
function is_realtime_export(
   p_ts_code in integer)
   return boolean
is
   l_count integer;
begin
   --------------------------------------------------------------------------
   -- determine if the ts_code participates in a realtime Oracle-->DSS set --
   --------------------------------------------------------------------------
   select count(*)
     into l_count
     from dual
    where exists(select null
                   from at_dss_xchg_set         xset,
                        at_dss_ts_xchg_map      xmap,
                        at_dss_ts_xchg_spec     xspec
                  where xspec.ts_code = p_ts_code
                    and xmap.dss_ts_xchg_code = xspec.dss_ts_xchg_code
                    and xset.dss_xchg_set_code = xmap.dss_xchg_set_code
                    and xset.realtime = (select dss_xchg_direction_code 
                                           from cwms_dss_xchg_direction 
                                          where dss_xchg_direction_id = 'OracleToDss'));
   return l_count = 1;
                                             
end is_realtime_export;   
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
--
function use_first_table(
   p_timestamp in timestamp default null) 
   return boolean
is
begin
   return mod(to_char(nvl(p_timestamp, systimestamp), 'MM'), 2) = 1;
end use_first_table;
                       
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
--
function use_first_table(
   p_timestamp in integer) 
   return boolean
   
is
begin
   return use_first_table(cwms_util.to_timestamp(p_timestamp));
end use_first_table;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in timestamp default null)
   return varchar2
is
begin              
   if use_first_table(p_timestamp) then return 'AT_TS_MSG_ARCHIVE_1'; end if;
   return 'AT_TS_MSG_ARCHIVE_2';
end get_table_name;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in integer default null)
   return varchar2
is
begin
   return get_table_name(cwms_util.to_timestamp(p_timestamp));
end get_table_name;   
   
-------------------------------------------------------------------------------
-- PROCEDURE XCHG_CONFIG_UPDATED(...)
--
procedure xchg_config_updated(
   p_urls_affected in varchar2)
is
   l_component   varchar2(32)  := 'DataExchangeConfigurationEditor';
   l_instance    varchar2(32)  := null;
   l_host        varchar2(32)  := null;
   l_port        integer       := null;
   l_reported    timestamp     := systimestamp;
   l_message     varchar2(4000);
   l_parts       cwms_util.str_tab_t;
   l_ts          integer;
begin
   l_message := '<cwms_message type="Status">'
                || '<property name="subtype" type="String">XchgConfigUpdated</property>'
                || '<property name="filemanagers" type="String">'
                || p_urls_affected
                || '</property></cwms_message>';
   
   l_ts := cwms_msg.log_message(l_component,l_instance,l_host,l_port,l_reported,l_message, true);                      
end xchg_config_updated;

-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED(...)
--
procedure time_series_updated(
   p_ts_code    in integer, 
   p_ts_id      in varchar2, 
   p_first_time in timestamp with time zone,
   p_last_time  in timestamp with time zone)
is
   pragma autonomous_transaction;
   l_msg        sys.aq$_jms_map_message;
   l_msgid      pls_integer;
   l_first_time timestamp;
   l_last_time  timestamp;
   i     integer;
begin
   --------------------------------------------------------------------------
   -- determine if the ts_code participates in a realtime Oracle-->DSS set --
   --------------------------------------------------------------------------
   if is_realtime_export(p_ts_code) then
      -------------------------------------------------------                     
      -- insert the time series update info into the table --
      -------------------------------------------------------
      l_first_time := sys_extract_utc(p_first_time);
      l_last_time  := sys_extract_utc(p_last_time);                     
      if use_first_table then
         ----------------
         -- odd months --
         ----------------
         insert 
           into at_ts_msg_archive_1 
         values (cwms_msg.get_msg_id,
                 p_ts_code, 
                 systimestamp, 
                 cast(l_first_time as date), 
                 cast(l_last_time as date));
      else
         -----------------
         -- even months --
         -----------------
         insert 
           into at_ts_msg_archive_2
         values (cwms_msg.get_msg_id,
                 p_ts_code, 
                 systimestamp, 
                 cast(l_first_time as date), 
                 cast(l_last_time as date));
      end if;

      -------------------------
      -- publish the message --
      -------------------------
      cwms_msg.new_message(l_msg, l_msgid, 'TSDataStored');
      l_msg.set_string(l_msgid, 'ts_id', p_ts_id);
      l_msg.set_long(l_msgid, 'start_time', cwms_util.to_millis(l_first_time));
      l_msg.set_long(l_msgid, 'end_time', cwms_util.to_millis(l_last_time));
      i := cwms_msg.publish_message(l_msg, l_msgid, 'realtime_ops');
   end if;

   commit;
   
end time_series_updated;   

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url  in varchar2,
   p_xchg_code   in integer,
   p_update_time in integer)
is
   l_log_msg varchar2(4000);
   i         integer;
   l_set_id  at_dss_xchg_set.dss_xchg_set_id%type;
begin
   -----------------------------
   -- update the exchange set --
   -----------------------------
   update_dss_xchg_set_time(p_xchg_code, cwms_util.to_timestamp(p_update_time));
   -------------------------
   -- publish the message --
   -------------------------
   select dss_xchg_set_id
     into l_set_id
     from at_dss_xchg_set
    where dss_xchg_set_code = p_xchg_code;
    
   l_log_msg := '<cwms_message type="Status">'
                || '<property type="String" name="subtype">LastProcessedTimeUpdated</property>'
                || '<property type="String" name="set_id">'
                || l_set_id
                || '</property>'
                || '<property type="long" name="last_processed">'
                || p_update_time
                || '</property>'
                || '</cwms_message>';
                
   i := cwms_msg.log_message('DataExchange Engine', p_engine_url, null, null, systimestamp, l_log_msg, true);
   
end update_last_processed_time;   
   
-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_engine_url      in varchar2,
   p_dss_xchg_set_id in varchar2,
   p_update_time     in integer,
   p_office_id       in varchar2 default null)
is
begin
   update_last_processed_time(
      p_engine_url,
      get_dss_xchg_set_code(p_dss_xchg_set_id, p_office_id),
      p_update_time);                              
end update_last_processed_time;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_component       in varchar2,
   p_host            in varchar2,
   p_dss_xchg_set_id in varchar2,
   p_start_time      in integer  default null,
   p_end_time        in integer  default null,
   p_request_id      in varchar2 default null,
   p_office_id       in varchar2 default null)
   return varchar2
is
   type assoc_bool_vc183 is table of boolean index by varchar2(183);
   l_reported      timestamp := systimestamp;
   l_start_time    timestamp;
   l_end_time      timestamp;
   l_log_msg       varchar2(4000);
   l_request_id    varchar2(64) := nvl(p_request_id, rawtohex(sys_guid()));
   l_message       sys.aq$_jms_map_message;
   l_messageid     pls_integer;
   l_message_count integer;
   l_tsids         assoc_bool_vc183;
   l_earliest      date;
   l_latest        date;
   l_ts            integer;
   l_xchg_code     integer := get_dss_xchg_set_code(p_dss_xchg_set_id, p_office_id);
   i               integer;
begin
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   if p_start_time is null then
      select last_update
        into l_start_time
        from at_dss_xchg_set
       where dss_xchg_set_code = l_xchg_code;
   else
      l_start_time := cwms_util.to_timestamp(p_start_time);
   end if;
   if p_end_time is null then
      l_end_time := systimestamp;
   else
      l_end_time := cwms_util.to_timestamp(p_end_time);
   end if;
   ----------------------------
   -- log the replay request --
   ----------------------------
   l_log_msg := '<cwms_message type="RequestAction">'
                || '<property type="String" name="subtype">ReplayRealtime</property>'
                || '<property type="String" name="user">'
                || cwms_util.get_user_id
                || '</property><property type="String" name="set_id">'
                || p_dss_xchg_set_id
                || '</property><property type="String" name="request_id">'
                || l_request_id
                || '</property><property type="String" name="start_time">'
                || l_start_time
                || '</property><property type="String" name="end_time">'
                || l_end_time
                || '</property></cwms_message>';
                
   i := cwms_msg.log_message(p_component, null, p_host, null, l_reported, l_log_msg, false);
   -------------------------------------
   -- loop over the archived messages --
   -------------------------------------
   for rec in (select msg.ts_code, 
                      msg.message_time,
                      msg.first_data_time,
                      msg.last_data_time,
                      tsid.cwms_ts_id 
                 from ((select * from at_ts_msg_archive_1) union (select * from at_ts_msg_archive_2)) msg,
                      mv_cwms_ts_id tsid
                where message_time between l_start_time and l_end_time
                  and msg.ts_code in (select ts_code
                                    from at_dss_ts_xchg_spec xspec,
                                         at_dss_ts_xchg_map  xmap
                                   where xmap.dss_xchg_set_code = l_xchg_code
                                     and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                                 )
             order by msg.message_time asc
              ) 
   loop
      ------------------------------
      -- keep track of statistics --
      ------------------------------
      l_message_count := l_message_count + 1;
      if not l_tsids.exists(rec.cwms_ts_id) then
         l_tsids(rec.cwms_ts_id) := true;
      end if;
      if l_earliest is null or rec.first_data_time < l_earliest then
         l_earliest := rec.first_data_time;
      end if;
      if l_latest is null or rec.last_data_time < l_latest then
         l_latest := rec.last_data_time;
      end if;
      --------------------------------
      -- publish the replay message --
      --------------------------------
      cwms_msg.new_message(l_message, l_messageid, 'TSDataStored');
      l_message.set_string(l_messageid, 'ts_id', rec.cwms_ts_id);
      l_message.set_long(l_messageid, 'start_time', cwms_util.to_millis(to_timestamp(rec.first_data_time)));
      l_message.set_long(l_messageid, 'end_time', cwms_util.to_millis(to_timestamp(rec.last_data_time)));
      l_message.set_long(l_messageid, 'original_millis', cwms_util.to_millis(rec.message_time));
      l_message.set_string(l_messageid, 'replay_id', l_request_id);
      l_ts := cwms_msg.publish_message(l_message, l_messageid, 'realtime_ops');
   end loop;
   ------------------------------------------
   -- publish the replay completed message --
   ------------------------------------------
   cwms_msg.new_message(l_message, l_messageid, 'TSReplayDone');
   l_message.set_string(l_messageid, 'replay_id', l_request_id);
   l_message.set_int(l_messageid, 'message_count', l_message_count);
   l_message.set_int(l_messageid, 'ts_id_count', l_tsids.count);
   l_message.set_long(l_messageid, 'first_time', cwms_util.to_millis(to_timestamp(l_earliest)));
   l_message.set_long(l_messageid, 'last_time', cwms_util.to_millis(to_timestamp(l_latest)));
   l_ts := cwms_msg.publish_message(l_message, l_messageid, 'realtime_ops');
   return l_request_id;
end replay_data_messages;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_engine_url in varchar2)
   return varchar2
is
   l_request_ids varchar2(4000) := '';
   l_engine_url  varchar2(256)  := regexp_replace(p_engine_url, '/DssFileManager$', '', 1, 1, 'i');
   l_host        varchar2(64)   := regexp_substr(l_engine_url, '[a-zA-Z0-9._]+');
begin
   for rec in (select dss_xchg_set_id
                 from at_dss_xchg_set xset,
                      at_dss_file     dfile
                where dfile.dss_filemgr_url = l_engine_url
                  and dfile.office_code = cwms_util.user_office_code
                  and xset.dss_file_code = dfile.dss_file_code
                  and xset.realtime is not null)
   loop
      l_request_ids := l_request_ids || ',' || replay_data_messages('DataExchange Engine', l_host, rec.dss_xchg_set_id);
   end loop;
   return substr(l_request_ids, 2);
end restart_realtime;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REQUEST_BATCH_EXCHANGE(...)
--
function request_batch_exchange(
   p_component        in varchar2,
   p_host             in varchar2,
   p_set_id           in varchar2,
   p_dst_datastore_id in varchar2,
   p_start_time       in integer,
   p_end_time         in integer  default null,
   p_office_id        in varchar2 default null)
   return varchar2
is
   l_job_id   varchar2(32) := rawtohex(sys_guid());
   l_log_msg  varchar2(4000);
   l_rt_msg   varchar2(4000);
   l_to_dss   varchar2(8);
   l_parts    cwms_util.str_tab_t;
   l_reported timestamp := systimestamp;
   l_rec      at_dss_file%rowtype;
   i          integer;
begin
   if p_dst_datastore_id = db_datastore_id then
      l_to_dss := 'false';
   else
      begin
         select dss_file_code
           into l_rec.dss_file_code
           from at_dss_xchg_set
          where dss_xchg_set_id = p_set_id;
         
         select *
           into l_rec
           from at_dss_file
          where dss_file_code = l_rec.dss_file_code;
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_set_id,
               'data exchange set id');
      end;
      if p_dst_datastore_id = dss_datastore_id(l_rec.dss_filemgr_url, l_rec.dss_file_name) then
         l_to_dss := 'true';
      else
         cwms_err.raise(
            'INVALID_ITEM',
            p_dst_datastore_id,
            'datastore id for data exchange set ' || p_set_id);
      end if;
   end if;
   l_log_msg := '<cwms_message type="RequestAction">'
                || '<property type="String" name="subtype">BatchExchange</property>'
                || '<property type="String" name="user">'
                || cwms_util.get_user_id
                || '</property><property type="String" name="set_id">'
                || p_set_id
                || '</property><property type="String" name="office_id">'
                || nvl(p_office_id, cwms_util.user_office_id)
                || '</property><property type="String" name="job_id">'
                || l_job_id
                || '</property><property type="long" name="start_time">'
                || p_start_time
                || '</property><property type="long" name="end_time">'
                || nvl(p_end_time, cwms_util.current_millis)
                || '</property><property type="String" name="destination_datastore_id">'
                || p_dst_datastore_id
                || '</property><property type="boolean" name="to_dss">'
                || l_to_dss
                || '</property></cwms_message>';
                
   l_parts := cwms_util.split_text(l_log_msg, '>', 1);
   
   i := cwms_msg.log_message(p_component, null, p_host, null, l_reported, l_log_msg, true);
   
   return l_job_id;
end request_batch_exchange;
   
end cwms_xchg;
/

commit;
show errors;


/* Formatted on 2006/05/09 20:37 (Formatter Plus v4.8.7) */
create or replace package body cwms_dss
as
--------------------------------------------------------------------------------
-- function get_office_code
--
   function get_office_code(
      p_office_id   in   varchar2)
      return number
   is
      l_office_code   number(10);
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = upper(p_office_id);

      return l_office_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_office_id, 'CWMS office');
   end get_office_code;

--------------------------------------------------------------------------------
-- procedure parse_dss_pathname
--
   procedure parse_dss_pathname(
      p_a_pathname_part   out      varchar2,
      p_b_pathname_part   out      varchar2,
      p_c_pathname_part   out      varchar2,
      p_d_pathname_part   out      varchar2,
      p_e_pathname_part   out      varchar2,
      p_f_pathname_part   out      varchar2,
      p_pathname          in       varchar2)
   is
      l_pathname   varchar2(512)  := upper(ltrim(rtrim(p_pathname)));
      pos          binary_integer;
      last_pos     binary_integer;

      procedure bad_pathname
      is
      begin
         cwms_err.raise('INVALID_ITEM', p_pathname, 'HEC-DSS pathname');
      end bad_pathname;
   begin
      if substr(l_pathname, 1, 1) != '/' then
         bad_pathname;
      end if;

      last_pos := 2;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_a_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_b_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_c_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_d_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_e_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;
      pos := instr(l_pathname, '/', last_pos);

      if pos = 0 then
         bad_pathname;
      end if;

      p_f_pathname_part := substr(l_pathname, last_pos, pos - last_pos);
      last_pos := pos + 1;

      if pos != length(l_pathname) then
         bad_pathname;
      end if;
   end parse_dss_pathname;

--------------------------------------------------------------------------------
-- function make_dss_ts_id(...)
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
      p_time_zone          in   varchar2 default null,
      p_tz_usage          in   varchar2 default null)
      return varchar2
   is
      l_dss_ts_id   varchar2(512);
   begin
      l_dss_ts_id :=
            '/'
         || nvl(p_a_pathname_part, '')
         || '/'
         || nvl(p_b_pathname_part, '')
         || '/'
         || nvl(p_c_pathname_part, '')
         || '/'
         || nvl(p_d_pathname_part, '')
         || '/'
         || nvl(p_e_pathname_part, '')
         || '/'
         || nvl(p_f_pathname_part, '')
         || '/';

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
-- function create_dss_file(...)
--
   function create_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_fail_if_exists    in   number default cwms_util.false_num)
      return number
   is
      l_dss_file_code   number;
   begin
      begin
         select dss_file_code
           into l_dss_file_code
           from at_dss_file
          where     dss_filemgr_url = p_dss_filemgr_url
                and dss_file_name = p_dss_file_name;

         if p_fail_if_exists != cwms_util.false_num then
            cwms_err.raise('ITEM_ALREADY_EXISTS',
                                 'HEC-DSS file',
                                 p_dss_filemgr_url || p_dss_file_name);
         end if;
      exception
         when no_data_found then
            begin
               insert into at_dss_file
                    values (cwms_seq.nextval, p_dss_filemgr_url,
                            p_dss_file_name)
                 returning dss_file_code
                      into l_dss_file_code;
            exception
               when others then
                  cwms_err.raise('ITEM_NOT_CREATED',
                                       'HEC-DSS file',
                                       p_dss_filemgr_url || p_dss_file_name);
            end;
      end;

      return l_dss_file_code;
   end create_dss_file;

--------------------------------------------------------------------------------
-- procedure delete_dss_file(...)
--
   procedure delete_dss_file(
      p_dss_file_code   in   number)
   is
   begin
      delete from at_dss_file
            where dss_file_code = p_dss_file_code;
   end delete_dss_file;

--------------------------------------------------------------------------------
-- procedure delete_dss_file(...)
--
   procedure delete_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2)
   is
      l_dss_file_code   number;
   begin
      select dss_file_code
        into l_dss_file_code
        from at_dss_file
       where     dss_filemgr_url = p_dss_filemgr_url
             and dss_file_name = p_dss_file_name;

      delete_dss_file(l_dss_file_code);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',
                              p_dss_filemgr_url || p_dss_file_name,
                              'HEC-DSS file');
   end delete_dss_file;

--------------------------------------------------------------------------------
-- function create_dss_xchg_set(...)
--
   function create_dss_xchg_set(
      p_office_id         in   varchar2,
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number default cwms_util.false_num)
      return number
   is
      l_office_code         number(10);
      l_dss_xchg_set_code   number(10)    := null;
      l_dss_file_code       number(10);
      l_description         varchar2(80);
      l_realtime_code_in    number(10)    := null;
      l_realtime_code       number(10)    := null;
      l_dss_filemgr_url     varchar2(32);
      l_dss_file_name       varchar2(255);
   begin
      l_office_code := get_office_code(p_office_id);

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
               cwms_err.raise('INVALID_ITEM',
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
          where     office_code = l_office_code
                and dss_xchg_set_id = p_dss_xchg_set_id;

         if    p_fail_if_exists != cwms_util.false_num
            or l_description != p_description
            or nvl(l_realtime_code, 0) != nvl(l_realtime_code_in, 0) then
            cwms_err.raise('ITEM_ALREADY_EXISTS',
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
           into l_dss_filemgr_url, l_dss_file_name
           from at_dss_file
          where dss_file_code = l_dss_file_code;

         if    l_dss_filemgr_url != p_dss_filemgr_url
            or l_dss_file_name != p_dss_file_name then
            cwms_err.raise('ITEM_ALREADY_EXISTS',
                                 'HEC-DSS exchange set',
                                 p_office_id || '/' || p_dss_xchg_set_id);
         end if;
      else
         ---------------------
         -- create the item --
         ---------------------
         l_dss_file_code :=
               create_dss_file(p_dss_filemgr_url, p_dss_file_name, cwms_util.false_num);

         begin
            insert into at_dss_xchg_set
                 values (cwms_seq.nextval, l_office_code, l_dss_file_code,
                         p_dss_xchg_set_id, p_description,
                         l_realtime_code_in, null)
              returning dss_xchg_set_code
                   into l_dss_xchg_set_code;
         exception
            when others then
               cwms_err.raise('ITEM_NOT_CREATED',
                                    'HEC-DSS exchange set',
                                    p_office_id || '/' || p_dss_xchg_set_id);
         end;
      end if;

      return l_dss_xchg_set_code;
   end create_dss_xchg_set;

--------------------------------------------------------------------------------
-- procedure create_dss_xchg_set(...)
--
   procedure create_dss_xchg_set(
      p_dss_xchg_set_code   out      number,
      p_office_id           in       varchar2,
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
      p_realtime            in       varchar2 default null,
      p_fail_if_exists      in       number default cwms_util.false_num)
   is
   begin
      p_dss_xchg_set_code :=
         create_dss_xchg_set(p_office_id,
                             p_dss_xchg_set_id,
                             p_description,
                             p_dss_filemgr_url,
                             p_dss_file_name,
                             p_realtime,
                             p_fail_if_exists);
   end create_dss_xchg_set;

---------------------------------------------------------------------------------
-- procedure delete_dss_xchg_set(...)
--
   procedure delete_dss_xchg_set(
      p_dss_xchg_set_code   in   number)
   is
   begin
      delete from at_dss_ts_xchg_map
            where dss_xchg_set_code = p_dss_xchg_set_code;

      delete from at_dss_xchg_set
            where dss_xchg_set_code = p_dss_xchg_set_code;
   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- procedure delete_dss_xchg_set(...)
--
   procedure delete_dss_xchg_set(
      p_office_id         in   varchar2,
      p_dss_xchg_set_id   in   varchar2)
   is
      l_office_code         number(10);
      l_dss_xchg_set_code   number(10);
   begin
      l_office_code := get_office_code(p_office_id);

      select dss_xchg_set_code
        into l_dss_xchg_set_code
        from at_dss_xchg_set
       where     office_code = l_office_code
             and dss_xchg_set_id = p_dss_xchg_set_id;

      delete_dss_xchg_set(l_dss_xchg_set_code);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',
                              p_office_id || '/' || p_dss_xchg_set_id,
                              'HEC-DSS exchange set');
   end delete_dss_xchg_set;

-------------------------------------------------------------------------------
-- procedure rename_dss_xchg_set(...)
--
   procedure rename_dss_xchg_set(
      p_office_id             in   varchar2,
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2)
   is
      l_office_code         number(10);
      l_dss_xchg_set_code   number(10);
   begin
      l_office_code := get_office_code(p_office_id);

      begin
         begin
            select dss_xchg_set_code
              into l_dss_xchg_set_code
              from at_dss_xchg_set
             where     office_code = l_office_code
                   and dss_xchg_set_id = p_dss_xchg_set_id;
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM',
                                    p_office_id || '/' || p_dss_xchg_set_id,
                                    'HEC-DSS exchange set');
         end;

         select dss_xchg_set_code
           into l_dss_xchg_set_code
           from at_dss_xchg_set
          where     office_code = l_office_code
                and dss_xchg_set_id = p_new_dss_xchg_set_id;

         cwms_err.raise('ITEM_ALREADY_EXISTS',
                              'HEC-DSS exchange set',
                              p_office_id || '/' || p_new_dss_xchg_set_id);
      exception
         when no_data_found then
            update at_dss_xchg_set
               set dss_xchg_set_id = p_new_dss_xchg_set_id
             where     office_code = l_office_code
                   and dss_xchg_set_id = p_dss_xchg_set_id;
      end;
   end rename_dss_xchg_set;

-------------------------------------------------------------------------------
-- procedure duplicate_dss_xchg_set(...)
--
   procedure duplicate_dss_xchg_set(
      p_office_id             in   varchar2,
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2)
   is
      l_office_code             at_dss_xchg_set.office_code%type;
      l_dss_xchg_set_code       at_dss_xchg_set.dss_xchg_set_code%type;
      l_new_dss_xchg_set_code   at_dss_xchg_set.dss_xchg_set_code%type;
      l_dss_file_code           at_dss_xchg_set.dss_file_code%type;
      l_description             at_dss_xchg_set.description%type;
      l_realtime                at_dss_xchg_set.realtime%type;
   begin
      l_office_code := get_office_code(p_office_id);

      select dss_xchg_set_code, dss_file_code, description, realtime
        into l_dss_xchg_set_code, l_dss_file_code, l_description, l_realtime
        from at_dss_xchg_set
       where     office_code = l_office_code
             and dss_xchg_set_id = p_dss_xchg_set_id;

      begin
         select dss_xchg_set_code
           into l_new_dss_xchg_set_code
           from at_dss_xchg_set
          where     office_code = l_office_code
                and dss_xchg_set_id = p_new_dss_xchg_set_id;

         cwms_err.raise('ITEM_ALREADY_EXISTS',
                              'HEC-DSS exchange set',
                              p_office_id || '/' || p_new_dss_xchg_set_id);
      exception
         when no_data_found then
            begin
               insert into at_dss_xchg_set
                    values (cwms_seq.nextval, l_office_code, l_dss_file_code,
                            p_new_dss_xchg_set_id, l_description, l_realtime, null)
                 returning dss_xchg_set_code
                      into l_new_dss_xchg_set_code;

               insert into at_dss_ts_xchg_map
                  select cwms_seq.nextval, l_new_dss_xchg_set_code,
                         dss_ts_xchg_code
                    from at_dss_ts_xchg_map
                   where dss_xchg_set_code = l_dss_xchg_set_code;
            exception
               when others then
                  cwms_err.raise('ITEM_NOT_CREATED',
                                       'HEC-DSS exchange set',
                                          p_office_id
                                       || '/'
                                       || p_new_dss_xchg_set_id);
            end;
      end;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM',
                              p_dss_xchg_set_id,
                              'HEC-DSS exchange set');
   end duplicate_dss_xchg_set;

--------------------------------------------------------------------------------
-- function update_dss_xchg_set(...)
--
   function update_dss_xchg_set(
      p_office_id            in   varchar2,
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_update_description   in   number default cwms_util.true_num,
      p_update_filemgr_url   in   number default cwms_util.true_num,
      p_update_file_name     in   number default cwms_util.true_num,
      p_update_realtime      in   number default cwms_util.true_num)
      return number
   is
      update_description    boolean
                          := nvl(p_update_description, cwms_util.false_num) !=
                                                                    cwms_util.false_num;
      update_filemgr_url    boolean
                          := nvl(p_update_filemgr_url, cwms_util.false_num) !=
                                                                    cwms_util.false_num;
      update_file_name      boolean
                            := nvl(p_update_file_name, cwms_util.false_num) !=
                                                                    cwms_util.false_num;
      update_realtime       boolean
                             := nvl(p_update_realtime, cwms_util.false_num) !=
                                                                    cwms_util.false_num;
      l_office_code         at_dss_xchg_set.office_code%type;
      l_dss_xchg_set_code   at_dss_xchg_set.dss_xchg_set_code%type;
      l_realtime_code       at_dss_xchg_set.realtime%type            := null;
      l_dss_filemgr_url     at_dss_file.dss_filemgr_url%type         := null;
      l_dss_file_name       at_dss_file.dss_file_name%type           := null;
      l_dss_file_code       at_dss_file.dss_file_code%type           := null;
      sql_text              varchar2(1024);
   begin
      l_office_code := get_office_code(p_office_id);

      ---------------------------------------
      -- get the code for the exchange set --
      ---------------------------------------
      begin
         select dss_xchg_set_code
           into l_dss_xchg_set_code
           from at_dss_xchg_set
          where     office_code = l_office_code
                and dss_xchg_set_id = p_dss_xchg_set_id;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM',
                                 p_dss_xchg_set_id,
                                 'HEC-DSS exchange set');
      end;

      ------------------------------------
      -- verify the specified direction --
      ------------------------------------
      if     update_realtime
         and (p_realtime is not null) then
         begin
            select dss_xchg_direction_code
              into l_realtime_code
              from cwms_dss_xchg_direction
             where upper(dss_xchg_direction_id) = upper(p_realtime);
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM',
                                    p_realtime,
                                    'HEC-DSS exchange direction');
         end;
      end if;

      ---------------------------
      -- get the dss file info --
      ---------------------------
      if update_filemgr_url then
         if p_dss_filemgr_url is null then
            cwms_err.raise('INVALID_ITEM',
                                 'NULL',
                                 'HEC-DSS FileManager URL');
         end if;

         l_dss_filemgr_url := p_dss_filemgr_url;
      end if;

      if update_file_name then
         if p_dss_file_name is null then
            cwms_err.raise('INVALID_ITEM', 'NULL', 'HEC-DSS file name');
         end if;

         l_dss_file_name := p_dss_file_name;
      end if;

      if    update_filemgr_url
         or update_file_name then
         if l_dss_filemgr_url is null then
            select dss_filemgr_url
              into l_dss_filemgr_url
              from at_dss_file f, at_dss_xchg_set s
             where     f.dss_file_code = s.dss_file_code
                   and s.dss_xchg_set_code = l_dss_xchg_set_code;
         end if;

         if l_dss_file_name is null then
            select dss_file_name
              into l_dss_file_name
              from at_dss_file f, at_dss_xchg_set s
             where     f.dss_file_code = s.dss_file_code
                   and s.dss_xchg_set_code = l_dss_xchg_set_code;
         end if;

         l_dss_file_code :=
                           create_dss_file(l_dss_filemgr_url, l_dss_file_name);
      end if;

      ---------------------------------------------
      -- create and execute the UPDATE statement --
      ---------------------------------------------
      if    update_description
         or update_filemgr_url
         or update_file_name
         or update_realtime then
         sql_text := 'update at_dss_xchg_set set ';

         if update_description then
            sql_text := sql_text || 'description=''' || p_description || '''';

            if    update_filemgr_url
               or update_file_name
               or update_realtime then
               sql_text := sql_text || ', ';
            end if;
         end if;

         if    update_filemgr_url
            or update_file_name then
            sql_text := sql_text || 'dss_file_code=' || l_dss_file_code;

            if update_realtime then
               sql_text := sql_text || ', ';
            end if;
         end if;

         if update_realtime then
            if p_realtime is null then
               sql_text := sql_text || 'realtime=NULL';
            else
               sql_text := sql_text || 'realtime=' || l_realtime_code;
            end if;
         end if;

         sql_text :=
                sql_text || ' where dss_xchg_set_code=' || l_dss_xchg_set_code;

         execute immediate sql_text;
      end if;

      return l_dss_xchg_set_code;
   end update_dss_xchg_set;

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set(...)
--
   procedure update_dss_xchg_set(
      p_dss_xchg_set_code    out      number,
      p_office_id            in       varchar2,
      p_dss_xchg_set_id      in       varchar2,
      p_description          in       varchar2,
      p_dss_filemgr_url      in       varchar2,
      p_dss_file_name        in       varchar2,
      p_realtime             in       varchar2,
      p_update_description   in       number default cwms_util.true_num,
      p_update_filemgr_url   in       number default cwms_util.true_num,
      p_update_file_name     in       number default cwms_util.true_num,
      p_update_realtime      in       number default cwms_util.true_num)
   is
   begin
      p_dss_xchg_set_code :=
         update_dss_xchg_set(p_office_id,
                             p_dss_xchg_set_id,
                             p_description,
                             p_dss_filemgr_url,
                             p_realtime,
                             p_update_description,
                             p_update_filemgr_url,
                             p_update_file_name,
                             p_update_realtime);
   end update_dss_xchg_set;

-------------------------------------------------------------------------------
-- function create_dss_ts_spec(...)
--
   function create_dss_ts_spec(
      p_a_pathname_part      in   varchar2,
      p_b_pathname_part      in   varchar2,
      p_c_pathname_part      in   varchar2,
      p_e_pathname_part      in   varchar2,
      p_f_pathname_part      in   varchar2,
      p_dss_parameter_type   in   varchar2,
      p_units                in   varchar2,
      p_time_zone             in   varchar2,
      p_tz_usage             in   varchar2,
      p_fail_if_exists       in   number default cwms_util.false_num)
      return number
   is
      l_a_pathname_part           varchar2(64)
                                         := upper(nvl(p_a_pathname_part, ''));
      l_b_pathname_part           varchar2(64)
                                         := upper(nvl(p_b_pathname_part, ''));
      l_c_pathname_part           varchar2(64)
                                         := upper(nvl(p_c_pathname_part, ''));
      l_e_pathname_part           varchar2(64)
                                         := upper(nvl(p_e_pathname_part, ''));
      l_f_pathname_part           varchar2(64)
                                         := upper(nvl(p_f_pathname_part, ''));
      l_dss_ts_code               at_dss_ts_spec.dss_ts_code%type;
      l_dss_parameter_type_code   cwms_dss_parameter_type.dss_parameter_type_code%type;
      l_unit_code                 cwms_unit.unit_code%type;
      l_time_zone_code             cwms_time_zone.time_zone_code%type;
      l_tz_usage_code             cwms_tz_usage.tz_usage_code%type;
      l_dss_ts_id                 varchar2(512);
   begin
      ---------------------------------
      -- get the parameter type code --
      ---------------------------------
      begin
         select dss_parameter_type_code
           into l_dss_parameter_type_code
           from cwms_dss_parameter_type
          where dss_parameter_type_id = upper(p_dss_parameter_type);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM',
                                 p_dss_parameter_type,
                                 'DSS parameter type');
      end;

      -----------------------
      -- get the unit code --
      -----------------------
      begin
         select unit_code
           into l_unit_code
           from cwms_unit
          where unit_id = p_units;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_units, 'CWMS unit');
      end;

      ---------------------------
      -- get the time_zone code --
      ---------------------------
      begin
         select time_zone_code
           into l_time_zone_code
           from cwms_time_zone
          where time_zone_name = p_time_zone;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_TIME_ZONE', p_time_zone);
      end;

      ---------------------------
      -- get the tz usage code --
      ---------------------------
      begin
         select tz_usage_code
           into l_tz_usage_code
           from cwms_tz_usage
          where upper(tz_usage_id) = upper(p_tz_usage);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM',
                                 p_tz_usage,
                                 'CWMS time zone usage');
      end;

      begin
         select dss_ts_code
           into l_dss_ts_code
           from at_dss_ts_spec
          where     a_pathname_part = l_a_pathname_part
                and b_pathname_part = l_b_pathname_part
                and c_pathname_part = l_c_pathname_part
                and e_pathname_part = l_e_pathname_part
                and f_pathname_part = l_f_pathname_part
                and dss_parameter_type_code = l_dss_parameter_type_code
                and unit_code = l_unit_code
                and time_zone_code = l_time_zone_code
                and tz_usage_code = l_tz_usage_code;

         if p_fail_if_exists != cwms_util.false_num then
            l_dss_ts_id :=
               make_dss_ts_id(l_a_pathname_part,
                              l_b_pathname_part,
                              l_c_pathname_part,
                              null,
                              l_e_pathname_part,
                              l_f_pathname_part,
                              p_dss_parameter_type,
                              p_units,
                              p_time_zone,
                              p_tz_usage);
            cwms_err.raise('ITEM_ALREADY_EXISTS',
                                 'HEC-DSS time series specification',
                                 l_dss_ts_id);
         end if;
      exception
         when no_data_found then
            begin
               insert into at_dss_ts_spec
                    values (cwms_seq.nextval, l_a_pathname_part,
                            l_b_pathname_part, l_c_pathname_part,
                            l_e_pathname_part, l_f_pathname_part,
                            l_dss_parameter_type_code, l_unit_code,
                            l_time_zone_code, l_tz_usage_code)
                 returning dss_ts_code
                      into l_dss_ts_code;
            exception
               when others then
                  l_dss_ts_id :=
                     make_dss_ts_id(l_a_pathname_part,
                                    l_b_pathname_part,
                                    l_c_pathname_part,
                                    null,
                                    l_e_pathname_part,
                                    l_f_pathname_part,
                                    p_dss_parameter_type,
                                    p_units,
                                    p_time_zone,
                                    p_tz_usage);
                  cwms_err.raise('ITEM_NOT_CREATED',
                                       'HEC-DSS time series specification',
                                       l_dss_ts_id);
            end;
      end;

      return l_dss_ts_code;
   end create_dss_ts_spec;

--------------------------------------------------------------------------------
-- function create_dss_ts_xchg_spec(...)
--
   function create_dss_ts_xchg_spec(
      p_office_id            in   varchar2,
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_time_zone             in   varchar2 default null,
      p_tz_usage             in   varchar2 default null,
      p_fail_if_exists       in   number default cwms_util.false_num)
      return number
   is
      l_a_pathname_part            varchar2(64);
      l_b_pathname_part            varchar2(64);
      l_c_pathname_part            varchar2(64);
      l_d_pathname_part            varchar2(64);
      l_e_pathname_part            varchar2(64);
      l_f_pathname_part            varchar2(64);
      l_cwms_ts_code               number;
      l_dss_ts_code                number;
      l_precip_code                number;
      l_inst_code                  number;
      l_cwms_parameter_code        number;
      l_cwms_parameter_type_code   number;
      l_dss_parameter_type_code    number;
      l_unit_code                  number;
      l_time_zone_code              number;
      l_tz_usage_code              number;
      l_dss_ts_xchg_code           number;
      l_dss_ts_id                  varchar2(512);
      l_dss_parameter_type         varchar2(16);
      l_units                      varchar2(16);
      l_time_zone                   varchar2(28);
      l_tz_usage                   varchar2(16);
   begin
      parse_dss_pathname(l_a_pathname_part,
                         l_b_pathname_part,
                         l_c_pathname_part,
                         l_d_pathname_part,
                         l_e_pathname_part,
                         l_f_pathname_part,
                         p_dss_pathname);
      cwms_ts.create_ts_code(l_cwms_ts_code,
                                   p_office_id,
                                   p_cwms_ts_id,
                                   null);

      ------------------------
      -- DSS PARAMETER TYPE --
      ------------------------
      if p_dss_parameter_type is null then
         ------------------------------------------------------------------
         -- select DSS parameter type from CWMS parameter/parameter type --
         ------------------------------------------------------------------
         select parameter_type_code
           into l_inst_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst';

         select parameter_code, parameter_type_code
           into l_cwms_parameter_code, l_cwms_parameter_type_code
           from at_cwms_ts_spec
          where ts_code = l_cwms_ts_code;

         if l_cwms_parameter_type_code = l_inst_code then
            select base_parameter_code
              into l_precip_code
              from cwms_base_parameter
             where base_parameter_id = 'Precip';

            if l_cwms_parameter_code = l_precip_code then
               select dss_parameter_type_code
                 into l_dss_parameter_type_code
                 from cwms_dss_parameter_type
                where dss_parameter_type_id = 'INST-CUM';
            else
               select dss_parameter_type_code
                 into l_dss_parameter_type_code
                 from cwms_dss_parameter_type
                where dss_parameter_type_id = 'INST-VAL';
            end if;
         else
            begin
               select dss_parameter_type_code
                 into l_dss_parameter_type_code
                 from cwms_dss_parameter_type
                where parameter_type_code = l_cwms_parameter_type_code;
            exception
               when no_data_found then
                  select dss_parameter_type_code
                    into l_dss_parameter_type_code
                    from cwms_dss_parameter_type
                   where dss_parameter_type_id = 'INST-VAL';
            end;
         end if;
      else
         --------------------------------------
         -- use the parameter type passed in --
         --------------------------------------
         begin
            select dss_parameter_type_code
              into l_dss_parameter_type_code
              from cwms_dss_parameter_type
             where dss_parameter_type_id = upper(p_dss_parameter_type);
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM',
                                    p_dss_parameter_type,
                                    'HEC-DSS parameter type');
         end;
      end if;

      ---------------
      -- DSS UNITS --
      ---------------
      if p_units is null then
         --------------------------------------
         -- Use the CWMS units for DSS units --
         --------------------------------------
         select cp.unit_code
           into l_unit_code
           from cwms_base_parameter cp, at_cwms_ts_spec ts
          where     ts.ts_code = l_cwms_ts_code
                and cp.base_parameter_code = ts.parameter_code;
      else
         -----------------------------
         -- use the units passed in --
         -----------------------------
         begin
            select unit_code
              into l_unit_code
              from (select unit_code, unit_id
                      from cwms_unit
                    union
                    select unit_code, alias_id as unit_id
                      from at_unit_alias)
             where unit_id = p_units;
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM', p_units, 'unit');
         end;
      end if;

      ------------------
      -- DSS TIME_ZONE --
      ------------------
      if p_time_zone is null then
         -------------
         -- use UTC --
         -------------
         select time_zone_code
           into l_time_zone_code
           from cwms_time_zone
          where time_zone_name = 'UTC';
      else
         --------------------------------
         -- use the time_zone passed in --
         --------------------------------
         begin
            select time_zone_code
              into l_time_zone_code
              from cwms_time_zone
             where upper(time_zone_name) = upper(p_time_zone);
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM', p_time_zone, 'unit');
         end;
      end if;

      ------------------------
      -- DSS TIME_ZONE USAGE --
      ------------------------
      if p_tz_usage is null then
         ------------------
         -- use Standard --
         ------------------
         select tz_usage_code
           into l_tz_usage_code
           from cwms_tz_usage
          where tz_usage_id = 'Standard';
      else
         --------------------------------
         -- use the time_zone passed in --
         --------------------------------
         begin
            select tz_usage_code
              into l_tz_usage_code
              from cwms_tz_usage
             where upper(tz_usage_id) = upper(p_tz_usage);
         exception
            when no_data_found then
               cwms_err.raise('INVALID_ITEM', p_time_zone, 'unit');
         end;
      end if;

      ----------------------------------------------------------------------
      -- get the text identifiers back regardless of how we got the codes --
      ----------------------------------------------------------------------
      select dss_parameter_type_id
        into l_dss_parameter_type
        from cwms_dss_parameter_type
       where dss_parameter_type_code = l_dss_parameter_type_code;

      select unit_id
        into l_units
        from cwms_unit
       where unit_code = l_unit_code;

      select time_zone_name
        into l_time_zone
        from cwms_time_zone
       where time_zone_code = l_time_zone_code;

      select tz_usage_id
        into l_tz_usage
        from cwms_tz_usage
       where tz_usage_code = l_tz_usage_code;

      l_dss_ts_code :=
         create_dss_ts_spec(l_a_pathname_part,
                            l_b_pathname_part,
                            l_c_pathname_part,
                            l_e_pathname_part,
                            l_f_pathname_part,
                            l_dss_parameter_type,
                            l_units,
                            l_time_zone,
                            l_tz_usage);

      begin
         select dss_ts_xchg_code
           into l_dss_ts_xchg_code
           from at_dss_ts_xchg_spec
          where     ts_code = l_cwms_ts_code
                and dss_ts_code = l_dss_ts_code;

         if p_fail_if_exists != cwms_util.false_num then
            l_dss_ts_id :=
               make_dss_ts_id(l_a_pathname_part,
                              l_b_pathname_part,
                              l_c_pathname_part,
                              null,
                              l_e_pathname_part,
                              l_f_pathname_part,
                              l_dss_parameter_type,
                              l_units,
                              l_time_zone,
                              l_tz_usage);
            cwms_err.raise
                                ('ITEM_ALREADY_EXISTS',
                                 'HEC-DSS time series exchange specification',
                                    p_office_id
                                 || '/'
                                 || p_cwms_ts_id
                                 || '='
                                 || l_dss_ts_id);
         end if;
      exception
         when no_data_found then
            begin
               insert into at_dss_ts_xchg_spec
                    values (cwms_seq.nextval, l_cwms_ts_code, l_dss_ts_code)
                 returning dss_ts_xchg_code
                      into l_dss_ts_xchg_code;
            exception
               when others then
                  l_dss_ts_id :=
                     make_dss_ts_id(l_a_pathname_part,
                                    l_b_pathname_part,
                                    l_c_pathname_part,
                                    null,
                                    l_e_pathname_part,
                                    l_f_pathname_part,
                                    l_dss_parameter_type,
                                    l_units,
                                    l_time_zone,
                                    l_tz_usage);
                  cwms_err.raise
                                ('ITEM_NOT_CREATED',
                                 'HEC-DSS time series exchange specification',
                                    p_office_id
                                 || '/'
                                 || p_cwms_ts_id
                                 || '='
                                 || l_dss_ts_id);
            end;
      end;

      return l_dss_ts_xchg_code;
   end create_dss_ts_xchg_spec;

--------------------------------------------------------------------------------
-- procedure map_ts_in_xchg_set(...)
--
   procedure map_ts_in_xchg_set(
      p_dss_xchg_set_code    in   number,
      p_office_id            in   varchar2,
      p_cwms_ts_id           in   varchar2,
      p_dss_pathname         in   varchar2,
      p_dss_parameter_type   in   varchar2 default null,
      p_units                in   varchar2 default null,
      p_time_zone            in   varchar2 default null,
      p_tz_usage             in   varchar2 default null)
   is
      l_dss_ts_xchg_code       number;
      l_dss_ts_xchg_map_code   number;
   begin
      l_dss_ts_xchg_code :=
         create_dss_ts_xchg_spec(p_office_id,
                                 p_cwms_ts_id,
                                 p_dss_pathname,
                                 p_dss_parameter_type,
                                 p_units,
                                 p_time_zone,
                                 p_tz_usage);

      select dss_ts_xchg_map_code
        into l_dss_ts_xchg_map_code
        from at_dss_ts_xchg_map
       where     dss_xchg_set_code = p_dss_xchg_set_code
             and dss_ts_xchg_code = l_dss_ts_xchg_code;
   exception
      when no_data_found then
         insert into at_dss_ts_xchg_map
              values (cwms_seq.nextval, p_dss_xchg_set_code,
                      l_dss_ts_xchg_code);
   end map_ts_in_xchg_set;

--------------------------------------------------------------------------------
-- procedure unmap_all_ts_in_xchg_set(...)
--
   procedure unmap_all_ts_in_xchg_set(
      p_dss_xchg_set_code   in   number)
   is
   begin
      delete from at_dss_ts_xchg_map
            where dss_xchg_set_code = p_dss_xchg_set_code;
   end;

--------------------------------------------------------------------------------
-- procedure del_unused_dss_files(...)
--
   procedure del_unused_dss_files
   is
   begin
      delete from at_dss_file
            where dss_file_code not in(select distinct dss_file_code
                                                  from at_dss_xchg_set);
   end del_unused_dss_files;

--------------------------------------------------------------------------------
-- procedure del_unused_dss_ts_xchg_specs(...)
--
   procedure del_unused_dss_ts_xchg_specs
   is
   begin
      delete from at_dss_ts_xchg_spec
            where dss_ts_xchg_code not in(select distinct dss_ts_xchg_code
                                                     from at_dss_ts_xchg_map);
   end del_unused_dss_ts_xchg_specs;

--------------------------------------------------------------------------------
-- procedure del_unused_dss_ts_specs(...)
--
   procedure del_unused_dss_ts_specs
   is
   begin
      delete from at_dss_ts_spec
            where dss_ts_code not in(select distinct dss_ts_code
                                                from at_dss_ts_xchg_spec);
   end del_unused_dss_ts_specs;

--------------------------------------------------------------------------------
-- procedure del_unused_dss_xchg_info(...)
--
   procedure del_unused_dss_xchg_info
   is
   begin
      del_unused_dss_files;
      del_unused_dss_ts_xchg_specs;
      del_unused_dss_ts_specs;
   end del_unused_dss_xchg_info;
end cwms_dss;
/

show errors;
commit ;

CREATE OR REPLACE package body cwms_dss
as
--------------------------------------------------------------------------------
-- function get_dss_xchg_set_code
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
-- function get_dss_xchg_direction_code
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
-- function get_dss_parameter_type_code
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
-- function get_dss_parameter_type_code
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
-- function get_dss_parameter_type_id
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
-- procedure parse_dss_pathname
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
      l_parts := cwms_util.split_text(upper(trim(p_pathname)), '/');
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
-- function make_dss_pathname
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
-- function make_dss_ts_id(...)
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
-- function create_dss_file(...)
--
   function create_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_fail_if_exists    in   number default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
      return number
   is
      l_dss_file_code  number(10);
      l_office_code    varchar2(16);
   begin
      l_office_code := cwms_util.get_office_code(p_office_id);
      begin
         select dss_file_code
           into l_dss_file_code
           from at_dss_file
          where office_code = l_office_code
            and dss_filemgr_url = p_dss_filemgr_url
            and dss_file_name = p_dss_file_name;

         if p_fail_if_exists != cwms_util.false_num then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'HEC-DSS file',
               p_dss_filemgr_url || p_dss_file_name);
         end if;
      exception
         when no_data_found then
            begin
               insert
                 into at_dss_file
               values (cwms_seq.nextval, l_office_code, p_dss_filemgr_url, p_dss_file_name)
             returning dss_file_code
                  into l_dss_file_code;
            exception
               when others then
                  cwms_err.raise(
                     'ITEM_NOT_CREATED',
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
      delete
        from at_dss_file
       where dss_file_code = p_dss_file_code;
   end delete_dss_file;

--------------------------------------------------------------------------------
-- procedure delete_dss_file(...)
--
   procedure delete_dss_file(
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_office_id         in   varchar2 default null)
   is
      l_dss_file_code   number;
   begin
      select dss_file_code
        into l_dss_file_code
        from at_dss_file
       where office_code = cwms_util.get_office_code(p_office_id)
         and dss_filemgr_url = p_dss_filemgr_url
         and dss_file_name = p_dss_file_name;

      delete_dss_file(l_dss_file_code);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_dss_filemgr_url || p_dss_file_name,
            'HEC-DSS file');
   end delete_dss_file;

--------------------------------------------------------------------------------
-- function create_dss_xchg_set(...)
--
   function create_dss_xchg_set(
      p_dss_xchg_set_id   in   varchar2,
      p_description       in   varchar2,
      p_dss_filemgr_url   in   varchar2,
      p_dss_file_name     in   varchar2,
      p_realtime          in   varchar2 default null,
      p_fail_if_exists    in   number   default cwms_util.false_num,
      p_office_id         in   varchar2 default null)
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
           into l_dss_filemgr_url, l_dss_file_name
           from at_dss_file
          where dss_file_code = l_dss_file_code;

         if l_dss_filemgr_url != p_dss_filemgr_url
            or
            l_dss_file_name != p_dss_file_name then
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
            p_dss_filemgr_url,
            p_dss_file_name,
            cwms_util.false_num,
            p_office_id);

         begin
            insert
              into at_dss_xchg_set
            values (cwms_seq.nextval, l_office_code, l_dss_file_code,
                   p_dss_xchg_set_id, p_description,
                   l_realtime_code_in, null)
         returning dss_xchg_set_code
              into l_dss_xchg_set_code;

         exception
            when others then
               cwms_err.raise(
                  'ITEM_NOT_CREATED',
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
      p_dss_xchg_set_id     in       varchar2,
      p_description         in       varchar2,
      p_dss_filemgr_url     in       varchar2,
      p_dss_file_name       in       varchar2,
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
         p_realtime,
         p_fail_if_exists,
         p_office_id);
   end create_dss_xchg_set;

---------------------------------------------------------------------------------
-- procedure delete_dss_xchg_set(...)
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
-- procedure delete_dss_xchg_set(...)
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
-- procedure rename_dss_xchg_set(...)
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
-- procedure duplicate_dss_xchg_set(...)
--
   procedure duplicate_dss_xchg_set(
      p_dss_xchg_set_id       in   varchar2,
      p_new_dss_xchg_set_id   in   varchar2,
      p_office_id             in   varchar2 default null)
   is
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
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_new_dss_xchg_set_id,
            'HEC-DSS exchange set');

      when already_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'HEC-DSS exchange set',
            p_office_id || '/' || p_new_dss_xchg_set_id);
   end duplicate_dss_xchg_set;

--------------------------------------------------------------------------------
-- function update_dss_xchg_set(...)
--
   function update_dss_xchg_set(
      p_dss_xchg_set_id      in   varchar2,
      p_description          in   varchar2,
      p_dss_filemgr_url      in   varchar2,
      p_dss_file_name        in   varchar2,
      p_realtime             in   varchar2,
      p_last_update          in   timestamp,
      p_update_description   in   number default cwms_util.true_num,
      p_update_filemgr_url   in   number default cwms_util.true_num,
      p_update_file_name     in   number default cwms_util.true_num,
      p_update_realtime      in   number default cwms_util.true_num,
      p_update_last_update   in   number default cwms_util.true_num,
      p_office_id            in   varchar2 default null)
      return number
   is
      l_update_description    boolean := nvl(p_update_description, cwms_util.true_num) != cwms_util.false_num;
      l_update_filemgr_url    boolean := nvl(p_update_filemgr_url, cwms_util.true_num) != cwms_util.false_num;
      l_update_file_name      boolean := nvl(p_update_file_name, cwms_util.true_num)   != cwms_util.false_num;
      l_update_realtime       boolean := nvl(p_update_realtime, cwms_util.true_num)    != cwms_util.false_num;
      l_update_last_update    boolean := nvl(p_update_last_update, cwms_util.true_num) != cwms_util.false_num;
      l_update                boolean := false;
      l_table_row             at_dss_xchg_set%rowtype;
      l_dss_xchg_set_code     number(10);
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

      savepoint update_dss_xchg_set_start;

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
               l_dss_file_row.dss_filemgr_url := p_dss_filemgr_url;
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

      return l_table_row.dss_xchg_set_code;

   exception
      when no_data_found then
         rollback to update_dss_xchg_set_start;
         cwms_err.raise(
            'INVALID_ITEM',
            p_office_id || '/' || p_dss_xchg_set_id,
            'HEC-DSS exchange set');

      when others then
         rollback to update_dss_xchg_set_start;
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
      p_update_description   in   number default cwms_util.true_num,
      p_update_filemgr_url   in   number default cwms_util.true_num,
      p_update_file_name     in   number default cwms_util.true_num,
      p_update_realtime      in   number default cwms_util.true_num,
      p_update_last_update   in   number default cwms_util.true_num,
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
         p_update_description,
         p_update_filemgr_url,
         p_update_file_name,
         p_update_realtime,
         p_update_last_update,
         p_office_id);
   end update_dss_xchg_set;

--------------------------------------------------------------------------------
-- procedure update_dss_xchg_set_time(...)
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
                  'Specified timestamp',
                  'timestamp for this exhange set because it pre-dates the existing last update time.');
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
      p_time_zone            in   varchar2,
      p_tz_usage             in   varchar2,
      p_fail_if_exists       in   number default cwms_util.false_num,
      p_office_id            in   varchar2 default null)
      return number
   is
      l_table_row at_dss_ts_spec%rowtype;
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
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
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
      end if;
      
      return l_table_row.dss_ts_code;

   exception
      when no_data_found then
         begin
            select cwms_seq.nextval into l_table_row.dss_ts_code from dual;
            insert  into at_dss_ts_spec values l_table_row;
            return l_table_row.dss_ts_code;

         exception
            when others then
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

   end create_dss_ts_spec;

-------------------------------------------------------------------------------
-- function create_dss_ts_spec(...)
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
-- function create_dss_ts_xchg_spec(...)
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
      dbms_output.put_line(''||systimestamp||' Creating savepoint in create_dss_ts_xchg_spec.');
      savepoint create_dss_ts_xchg_spec_start;
      dbms_output.put_line(''||systimestamp||' Getting office id for '||nvl(p_office_id, 'NULL')||' in create_dss_ts_xchg_spec.');
      if p_office_id is null then
         l_office_id := cwms_util.user_office_id;
      else
         l_office_id := p_office_id;
      end if;
      
      dbms_output.put_line(''||systimestamp||' Getting/creating CWMS ts code in create_dss_ts_xchg_spec.');
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
      dbms_output.put_line(''||systimestamp||' Getting DSS parameter type in create_dss_ts_xchg_spec.');
      if p_dss_parameter_type is null then
         l_dss_parameter_type_code := get_dss_parameter_type_code(l_cwms_ts_code);
      else
         l_dss_parameter_type_code := get_dss_parameter_type_code(p_dss_parameter_type);
      end if;
      ---------------
      -- DSS UNITS --
      ---------------
      dbms_output.put_line(''||systimestamp||' Getting DSS units in create_dss_ts_xchg_spec.');
      if p_units is null then
         l_unit_id := cwms_ts.get_db_unit_id(p_cwms_ts_id);
      else
         l_unit_id := p_units;
      end if;
      ------------------
      -- DSS TIME_ZONE --
      ------------------
      dbms_output.put_line(''||systimestamp||' Getting DSS time zone in create_dss_ts_xchg_spec.');
      if p_time_zone is null then
         l_time_zone_code := cwms_util.get_time_zone_code('UTC');
      else
         l_time_zone_code := cwms_util.get_time_zone_code(p_time_zone);
      end if;
      ------------------------
      -- DSS TIME_ZONE USAGE --
      ------------------------
      dbms_output.put_line(''||systimestamp||' Getting DSS tz usage in create_dss_ts_xchg_spec.');
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
      dbms_output.put_line(''||systimestamp||' Getting/creating DSS ts code in create_dss_ts_xchg_spec.');
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
         dbms_output.put_line(''||systimestamp||' Looking up xchg spec in create_dss_ts_xchg_spec.');
         select dss_ts_xchg_code
           into l_dss_ts_xchg_code
           from at_dss_ts_xchg_spec
          where ts_code = l_cwms_ts_code
            and dss_ts_code = l_dss_ts_code;

         -----------------------------------
         -- it exists, fail if we need to --
         -----------------------------------
         if p_fail_if_exists != cwms_util.false_num then
            rollback to create_dss_ts_xchg_spec_start;
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
            dbms_output.put_line(''||systimestamp||' Creating new xchg spec in create_dss_ts_xchg_spec.');
            begin
               insert into at_dss_ts_xchg_spec
                    values (cwms_seq.nextval, l_cwms_ts_code, l_dss_ts_code)
                 returning dss_ts_xchg_code
                      into l_dss_ts_xchg_code;
            exception
               when others then
                  rollback to create_dss_ts_xchg_spec_start;
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
      
      dbms_output.put_line(''||systimestamp||' Done in create_dss_ts_xchg_spec.');
      return l_dss_ts_xchg_code;
      
   end create_dss_ts_xchg_spec;

--------------------------------------------------------------------------------
-- procedure map_ts_in_xchg_set(...)
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
      l_dss_xchg_set_id  at_dss_xchg_set.dss_xchg_set_id%type;
      l_dss_ts_xchg_code number;
      l_dss_ts_xchg_map  at_dss_ts_xchg_map%rowtype;
      l_dss_ts_spec      at_dss_ts_spec%rowtype;
      l_ts_code          number;
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
      cwms_ts.create_ts_code(l_ts_code, p_cwms_ts_id, null, null, null, 'F', 'T', 'F', p_office_id);
      begin
         dbms_output.put_line(''||systimestamp||' Checking for existing mapping.');
         select *
           into l_dss_ts_spec
           from at_dss_ts_spec
          where office_code = l_office_code
            and nvl(a_pathname_part, '@') = nvl(l_a_part, '@')
            and b_pathname_part = l_b_part
            and c_pathname_part = l_c_part
            and e_pathname_part = l_e_part
            and nvl(f_pathname_part, '@') = nvl(l_f_part, '@')
            and dss_ts_code in (select dss_ts_code
                                  from at_dss_ts_xchg_spec xspec,
                                       at_dss_ts_xchg_map xmap
                                 where xmap.dss_xchg_set_code = p_dss_xchg_set_code
                                   and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                                   and xspec.ts_code = l_ts_code);

         if l_dss_ts_spec.dss_parameter_type_code != get_dss_parameter_type_code(p_dss_parameter_type)
            or l_dss_ts_spec.unit_id != p_units
            or l_dss_ts_spec.time_zone_code != cwms_util.get_time_zone_code(p_time_zone)
            or l_dss_ts_spec.tz_usage_code != cwms_util.get_tz_usage_code(p_tz_usage) then

            select dss_xchg_set_id 
              into l_dss_xchg_set_id 
              from at_dss_xchg_set
             where dss_xchg_set_code = p_dss_xchg_set_code;
            
            cwms_err.raise(
               'DUPLICATE_XCHG_MAP',
               p_cwms_ts_id,
               p_dss_pathname,
               l_dss_xchg_set_id);
         end if;
         
      exception
         when no_data_found then null;
         
      end;

      dbms_output.put_line(''||systimestamp||' Getting/creating ts xchg spec.');
      begin
         select dss_ts_xchg_code
           into l_dss_ts_xchg_code
           from at_dss_ts_xchg_spec
          where ts_code = l_ts_code
            and dss_ts_code = l_dss_ts_spec.dss_ts_code;
      exception
         when no_data_found then
            l_dss_ts_xchg_code := create_dss_ts_xchg_spec(
                  p_cwms_ts_id,
                  p_dss_pathname,
                  p_dss_parameter_type,
                  p_units,
                  p_time_zone,
                  p_tz_usage,
                  cwms_util.false_num,
                  p_office_id);
      end;

      dbms_output.put_line(''||systimestamp||' Getting ts xchg spec map.');
      select *
        into l_dss_ts_xchg_map
        from at_dss_ts_xchg_map
       where dss_xchg_set_code = p_dss_xchg_set_code
         and dss_ts_xchg_code = l_dss_ts_xchg_code;
      dbms_output.put_line(''||systimestamp||' Done getting ts xchg spec map.');
   exception
      when no_data_found then
         dbms_output.put_line(''||systimestamp||' Creating ts xchg spec map.');
         select cwms_seq.nextval into l_dss_ts_xchg_map.dss_ts_xchg_map_code from dual;
         l_dss_ts_xchg_map.dss_xchg_set_code := p_dss_xchg_set_code;
         l_dss_ts_xchg_map.dss_ts_xchg_code  := l_dss_ts_xchg_code;
         insert 
           into at_dss_ts_xchg_map
         values l_dss_ts_xchg_map;
         dbms_output.put_line(''||systimestamp||' Done creating ts xchg spec map.');
   end map_ts_in_xchg_set;

--------------------------------------------------------------------------------
-- procedure unmap_ts_in_xchg_set(...)
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
-- function get_dss_xchg_sets
--
   function get_dss_xchg_sets(
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null)
      return clob
   is
      l_dss_filemgr_url at_dss_file.dss_filemgr_url%type;
      l_dss_file_name   at_dss_file.dss_file_name%type;
      l_dss_xchg_set_id at_dss_xchg_set.dss_xchg_set_id%type;
      l_office_code     cwms_office.office_code%type;
      l_office_id_mask  cwms_office.office_id%type;
      l_office_id       cwms_office.office_id%type;
      l_office_name     cwms_office.long_name%type;
      l_db_name         v$database.name%type;
      l_dss_filemgr_id  varchar2(256);
      l_oracle_id       varchar2(256);
      l_xml             clob;
      l_level           binary_integer := 0;
      l_spc             varchar2(1) := chr(9);
      l_nl              varchar2(1) := chr(10);
      l_indent_str      varchar2(256) := null;
      l_text            varchar2(32767) := null;
      l_parts           cwms_util.str_tab_t;
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

      function dec2hex(dec in binary_integer) return varchar2 is 
          l_number binary_integer := dec;
          l_digit binary_integer;
          l_hex varchar2(32) := null;
          type char_tab_t is table of varchar2(1);
          stack char_tab_t := char_tab_t(); 
      begin
         loop
            exit when l_number = 0;
            stack.extend;  
            l_digit := mod(l_number, 16);
            if l_digit > 9 then
               stack(stack.last) := chr(ascii('a')+ l_digit - 10); 
            else
               stack(stack.last) := chr(ascii('0') + l_digit);
            end if;
            l_number := trunc(l_number / 16);
         end loop;
         for i in reverse 1..stack.count loop l_hex := l_hex || stack(i); end loop;    
         return l_hex;
      end;
   begin
      l_dss_filemgr_url := cwms_util.normalize_wildcards(p_dss_filemgr_url);
      l_dss_file_name   := cwms_util.normalize_wildcards(p_dss_file_name);
      l_dss_xchg_set_id := cwms_util.normalize_wildcards(p_dss_xchg_set_id);
      if p_office_id is null then
         l_office_id_mask := cwms_util.get_office_code;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id);
      end if;
      
      dbms_output.put_line('l_dss_filemgr_url = ' || l_dss_filemgr_url);
      dbms_output.put_line('l_dss_file_name   = ' || l_dss_file_name);
      dbms_output.put_line('l_dss_xchg_set_id = ' || l_dss_xchg_set_id);
      dbms_output.put_line('l_office_id_mask  = ' || l_office_id_mask);
      
      select name into l_db_name from v$database;
      l_oracle_id := utl_inaddr.get_host_name || ':' || l_db_name;
      
      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_xml('<?xml version="1.0" encoding="UTF-8"?>');
      writeln_xml('<cwms_dataexchangeconfiguration');
      indent;
      writeln_xml('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
      writeln_xml('xsi:noNamespaceSchemaLocation="dataexchangeconfiguration.xsd">');

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
            if l_parts is null then
               l_parts := cwms_util.str_tab_t();
            end if;
            l_parts.extend(3);
            l_parts(1) := regexp_substr(set_info.dss_file_name, '[^/]+$');
            l_parts(1) := substr(l_parts(1), 1, length(l_parts(1)) - 4);
            l_parts(1) := substr(l_parts(1), -(least(length(l_parts(1)), 8)));
            l_parts(2) := replace(replace(regexp_substr(set_info.dss_filemgr_url, '[^/]+'), '.', ''), ':', '');
            l_parts(2) := substr(l_parts(2), 1, length(l_parts(2)) - 3) || ':';
            l_parts(2) := substr(l_parts(2), -(least(length(l_parts(2)), 16 - length(l_parts(1)))));
            l_parts(3) := l_parts(2) || l_parts(1);
            declare
               i pls_integer := 1;
            begin
               while l_filemgr_ids.exists(l_parts(3)) loop
                  i := i + 1;
                  l_parts(2) := to_char(i);
                  l_parts(3) := substr(l_parts(3), 1, length(l_parts(3)) - length(l_parts(2))) || l_parts(2);
               end loop;
            end;
            l_filemgr_ids(l_parts(3)) := '';
            l_filemgrs(l_text) := l_parts(3);
            l_parts.trim(3);
         end if;
      end loop;
      
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
      
      l_filemgr_ids.delete;
      l_text := l_filemgrs.first;
      loop
         exit when l_text is null;
         l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
         l_filemgr_ids(l_parts(2)) := l_filemgrs(l_text);
         writeln_xml('<datastore>');
         indent;
         writeln_xml('<dssfilemanager id="'||l_filemgrs(l_text)||'" officeid="'||l_parts(1)||'">');
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
         if set_info.realtime is null then
            writeln_xml(
               '<dataexchangeset  id="'
               || set_info.dss_xchg_set_id
               || '" officeid="'
               || set_info.office_id
               ||'">');
         else
            if set_info.realtime = 1 then
               writeln_xml(
                  '<dataexchangeset  id="'
                  || set_info.dss_xchg_set_id
                  || '" officeid="'
                  || set_info.office_id
                  || '" realtime_sourceid="'
                  || l_filemgr_ids(l_dss_filemgr_id)
                  || '">');
            else
               writeln_xml(
                  '<dataexchangeset  id="'
                  || set_info.dss_xchg_set_id
                  || '" officeid="'
                  || set_info.office_id
                  || '" realtime_sourceid="'
                  || l_oracle_id
                  || '">');
            end if;
         end if;
         indent;
         writeln_xml('<description>'||set_info.description||'</description>');
         writeln_xml('<datastore_ref id="'||l_oracle_id||'"/>');
         writeln_xml('<datastore_ref id="'||l_filemgr_ids(l_dss_filemgr_id)||'"/>');
         writeln_xml('<tsmappingset>');
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
            writeln_xml('<tsmapping>');
            indent;
            writeln_xml(
               '<cwms_timeseries datastoreid="'
               || l_oracle_id
               || '">');
            indent;
            writeln_xml(map_info.cwms_ts_id);
            dedent;
            writeln_xml('</cwms_timeseries>');
            writeln_xml(
               '<dss_timeseries datastoreid="'
               || l_filemgr_ids(l_dss_filemgr_id)
               || '" timezone="'
               || map_info.time_zone_name
               || '" tz_usage="' 
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
            writeln_xml('</dss_timeseries>');
            dedent;
            writeln_xml('</tsmapping>');
         end loop;
         dedent;
         writeln_xml('</tsmappingset>');
         dedent;
         writeln_xml('</dataexchangeset>');
      end loop;
      
      dedent;
      writeln_xml('</cwms_dataexchangeconfiguration>');
      dbms_lob.close(l_xml);
      return l_xml;
   end get_dss_xchg_sets;
   
   function get_dss_xchg_sets_orig(
      p_dss_filemgr_url in varchar2 default null,
      p_dss_file_name   in varchar2 default null,
      p_dss_xchg_set_id in varchar2 default null,
      p_office_id       in varchar2 default null)
      return clob
   is
      l_dss_filemgr_url at_dss_file.dss_filemgr_url%type;
      l_dss_file_name   at_dss_file.dss_file_name%type;
      l_dss_xchg_set_id at_dss_xchg_set.dss_xchg_set_id%type;
      l_office_code     cwms_office.office_code%type;
      l_office_id_mask  cwms_office.office_id%type;
      l_office_id       cwms_office.office_id%type;
      l_office_name     cwms_office.long_name%type;
      l_db_name         v$database.name%type;
      l_dss_filemgr_id  varchar2(256);
      l_oracle_id       varchar2(256);
      l_xml             clob;
      l_level           binary_integer := 0;
      l_spc             varchar2(1) := chr(9);
      l_nl              varchar2(1) := chr(10);
      l_indent_str      varchar2(256) := null;
      l_text            varchar2(32767) := null;
      l_parts           cwms_util.str_tab_t;
      type assoc_ary_t is table of boolean index by varchar2(32767);
      l_offices         assoc_ary_t; 
      l_filemgrs        assoc_ary_t; 
      
      cursor xchg_set_cur is
         select dss_filemgr_url,
                dss_file_name,
                f.dss_file_code,
                office_id,
                dss_xchg_set_code,
                dss_xchg_set_id,
                description,
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

      function dec2hex(dec in binary_integer) return varchar2 is 
          l_number binary_integer := dec;
          l_digit binary_integer;
          l_hex varchar2(32) := null;
          type char_tab_t is table of varchar2(1);
          stack char_tab_t := char_tab_t(); 
      begin
         loop
            exit when l_number = 0;
            stack.extend;  
            l_digit := mod(l_number, 16);
            if l_digit > 9 then
               stack(stack.last) := chr(ascii('a')+ l_digit - 10); 
            else
               stack(stack.last) := chr(ascii('0') + l_digit);
            end if;
            l_number := trunc(l_number / 16);
         end loop;
         for i in reverse 1..stack.count loop l_hex := l_hex || stack(i); end loop;    
         return l_hex;
      end;
   begin
      l_dss_filemgr_url := cwms_util.normalize_wildcards(p_dss_filemgr_url);
      l_dss_file_name   := cwms_util.normalize_wildcards(p_dss_file_name);
      l_dss_xchg_set_id := cwms_util.normalize_wildcards(p_dss_xchg_set_id);
      if p_office_id is null then
         l_office_id_mask := cwms_util.get_office_code;
      else
         l_office_id_mask := cwms_util.normalize_wildcards(p_office_id);
      end if;
      
      dbms_output.put_line('l_dss_filemgr_url = ' || l_dss_filemgr_url);
      dbms_output.put_line('l_dss_file_name   = ' || l_dss_file_name);
      dbms_output.put_line('l_dss_xchg_set_id = ' || l_dss_xchg_set_id);
      dbms_output.put_line('l_office_id_mask  = ' || l_office_id_mask);
      
      select name into l_db_name from v$database;
      l_oracle_id := utl_inaddr.get_host_name || ':' || l_db_name;
      
      dbms_lob.createtemporary(l_xml, true);
      dbms_lob.open(l_xml, dbms_lob.lob_readwrite);
      writeln_xml('<?xml version="1.0" encoding="UTF-8"?>');
      writeln_xml('<dataexchangeconfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

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
                  l_offices(l_text) := true;
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
         if not l_filemgrs.exists (l_text) then
            l_filemgrs(l_text) := true;
         end if;
      end loop;
      
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
      
      l_text := l_filemgrs.first;
      loop
         exit when l_text is null;
         l_parts := cwms_util.split_text(l_text, cwms_util.field_separator);
         writeln_xml('<dssfilemanager id="'||l_parts(2)||'" officeid="'||l_parts(1)||'">');
         indent;
         writeln_xml('<host>'||l_parts(3)||'</host>');
         writeln_xml('<port>'||l_parts(4)||'</port>');
         writeln_xml('<filepath>'||l_parts(5)||'</filepath>');
         dedent;
         writeln_xml('</dssfilemanager>');
         l_text := l_filemgrs.next(l_text);
      end loop;

      writeln_xml('<oracle id="'||l_oracle_id||'">');
      indent;
      writeln_xml('<host>'||utl_inaddr.get_host_address||'</host>');
      writeln_xml('<sid>'||l_db_name||'</sid>');
      dedent;
      writeln_xml('</oracle>');

      for set_info in xchg_set_cur loop
         l_dss_filemgr_id := set_info.dss_filemgr_url || set_info.dss_file_name;
         writeln_xml(
            '<dataexchangeset  officeid="'
            || set_info.office_id
            || '" dssfileid="'
            || l_dss_filemgr_id
            ||'" oracleid="'
            || l_oracle_id
            ||'">');
         indent;
         writeln_xml('<name>'||set_info.dss_xchg_set_id||'</name>');
         writeln_xml('<description>'||set_info.description||'</description>');
         if set_info.realtime is not null then
            if set_info.realtime = 1 then
               writeln_xml(
                  '<realtime source="'
                  || l_dss_filemgr_id
                  || '" destination="'
                  || l_oracle_id
                  || '"/>');
            else
               writeln_xml(
                  '<realtime source="'
                  || l_oracle_id
                  || '" destination="'
                  || l_dss_filemgr_id
                  || '"/>');
            end if;
         end if;
         writeln_xml('<mappingset>');
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
            writeln_xml('<mapping>');
            indent;
            writeln_xml(
               '<cwmstimeseries>'
               || map_info.cwms_ts_id
               || '</cwmstimeseries>');
            writeln_xml(
               '<dsspathname timezone="'
               || map_info.time_zone_name
               || '" units="'
               || map_info.unit_id
               || '" type="'
               || map_info.dss_parameter_type_id
               || '">/' 
               || map_info.a_pathname_part || '/'
               || map_info.b_pathname_part || '/'
               || map_info.c_pathname_part || '//'
               || map_info.e_pathname_part || '/'
               || map_info.f_pathname_part || '/</dsspathname>');
            dedent;
            writeln_xml('</mapping>');
         end loop;
         dedent;
         writeln_xml('</mappingset>');
         dedent;
         writeln_xml('</dataexchangeset>');
      end loop;
      
      dedent;
      writeln_xml('</dataexchangeconfiguration>');
      dbms_lob.close(l_xml);
      return l_xml;
   end get_dss_xchg_sets_orig;
   
--------------------------------------------------------------------------------
-- procedure put_dss_xchg_sets
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
      type assoc_vc574_bool is table of boolean index by varchar2(574); -- 183 (tsid) + 391 (pathname)
      
      l_sets_inserted           binary_integer := 0;
      l_sets_updated            binary_integer := 0;
      l_mappings_inserted       binary_integer := 0;
      l_mappings_updated        binary_integer := 0;
      l_mappings_deleted        binary_integer := 0;
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
      l_specified_maps          assoc_vc574_bool;
      l_offices                 assoc_vc574_bool;
      
      function get_dss_file_code (p_full_url in varchar2, p_office_id in varchar2) return number
      is
         l_url  at_dss_file.dss_filemgr_url%type;
         l_fn   at_dss_file.dss_file_name%type;
      begin
         l_url  := regexp_substr(l_set_filemgr, '^//[^/]+');
         l_fn   := substr(l_set_filemgr, length(l_url)+1);
         return create_dss_file(l_url,l_fn,cwms_util.false_num,l_set_office_id); 
      end get_dss_file_code;
      
   begin
      savepoint put_dss_xchg_sets_start;
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
      if l_xml_document.getrootelement() != 'dataexchangeconfiguration' then
         cwms_err.raise(
            'INVALID_ITEM',
            l_xml_document.getrootelement(),
            'XML root element for HEC-DSS data exchange configuration.');
      end if;
      ------------------------
      -- get the office ids --
      ------------------------
      l_nodes := l_xml_document.extract('/dataexchangeconfiguration/office[@id]');
      if l_nodes is not null then
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']/@id');
            exit when l_node is null;
            l_offices(l_node.getstringval()) := true;
         end loop;
      end if;
      -----------------------
      -- get the xchg sets --
      -----------------------
      l_time1 := systimestamp;
      l_nodes := l_xml_document.extract('/dataexchangeconfiguration/dataexchangeset');
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
            l_set_name := trim(l_node.extract('name/node()').getstringval());
            l_mapping_nodes := l_node.extract('mappingset/mapping');
            if l_mapping_nodes is not null then
               j := 0;
               loop
                  j := j + 1;
                  l_mapping_node := l_mapping_nodes.extract('*['||j||']/*');
                  exit when l_mapping_node is null;
                  l_ts_id := trim(l_mapping_node.extract('cwmstimeseries/node()').getstringval());
                  l_dss_pathname := upper(trim(l_mapping_node.extract('dsspathname/node()').getstringval()));
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
            l_set_name := trim(l_node.extract('name/node()').getstringval());
            l_set_description := trim(l_node.extract('description/node()').getstringval());
            l_set_office_id := trim(l_nodes.extract('*['||i||']/@officeid').getstringval());
            l_set_filemgr := trim(l_nodes.extract('*['||i||']/@dssfileid').getstringval());
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
                  dbms_output.put_line(
                     'Changing "'
                     || l_xchg_set_rec.description
                     || '" to "'
                     || l_set_description
                     || '" for set '
                     || l_set_name);
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
                          null)
                returning dss_xchg_set_code,
                          office_code,
                          dss_file_code,
                          dss_xchg_set_id,
                          description,
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
            l_mapping_nodes := l_nodes.extract('*['||i||']/mappingset/mapping');
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
                     l_ts_id := trim(l_mapping_node.extract('cwmstimeseries/node()').getstringval());
                     l_dss_pathname := upper(trim(l_mapping_node.extract('dsspathname/node()').getstringval()));
                     if l_can_delete then
                        l_specified_maps(l_ts_id || l_dss_pathname) := true;
                     end if;
                     parse_dss_pathname(l_a_part,l_b_part,l_c_part,l_d_part,l_e_part,l_f_part,l_dss_pathname);
                     l_dss_time_zone_name := trim(l_mapping_node.extract('dsspathname/@timezone').getstringval());
                     if l_mapping_node.extract('dsspathname/@tz_usage') is null then
                        l_dss_tz_usage_id := 'Standard';
                     else
                        l_dss_tz_usage_id := trim(l_mapping_node.extract('dsspathname/@tz_usage').getstringval());
                     end if;
                     l_dss_units := trim(l_mapping_node.extract('dsspathname/@units').getstringval());
                     l_dss_parameter_type_id := upper(trim(l_mapping_node.extract('dsspathname/@type').getstringval()));
                     begin
                        cwms_ts.create_ts_code(l_ts_code, l_ts_id, null, null, null, 'F', 'T', 'T', l_set_office_id);
                        if not l_can_insert then
                           cwms_ts.delete_ts(l_ts_id, cwms_util.delete_ts_id, l_set_office_id);
                           exit map_one_pass_loop;
                           l_new_map := true;
                        end if;
                     exception
                        when others then
                           cwms_ts.create_ts_code(l_ts_code, l_ts_id, null, null, null, 'F', 'T', 'F', l_set_office_id);
                     end;
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
                        l_map_updated := false;
                        if l_can_update and not l_new_map then
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
                        elsif l_can_insert and l_new_map then
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
         rollback to put_dss_xchg_sets_start;
         raise;
         
   end put_dss_xchg_sets;
      
--------------------------------------------------------------------------------
-- procedure unmap_all_ts_in_xchg_set(...)
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
-- procedure del_unused_dss_files(...)
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
-- procedure del_unused_dss_ts_xchg_specs(...)
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
-- procedure del_unused_dss_ts_specs(...)
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
-- procedure del_unused_dss_xchg_info(...)
--
   procedure del_unused_dss_xchg_info(
      p_office_id in varchar2 default null)                                     
   is
   begin
      del_unused_dss_files;
      del_unused_dss_ts_xchg_specs;
      del_unused_dss_ts_specs(p_office_id);
   end del_unused_dss_xchg_info;
end cwms_dss;
/

/* Formatted on 2006/05/09 20:37 (Formatter Plus v4.8.7) */
create or replace package body cwms_dss
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
      l_table_row.office_code             := cwms_util.get_office_code(p_office_id);
      l_table_row.a_pathname_part         := upper(p_a_pathname_part);
      l_table_row.b_pathname_part         := upper(p_b_pathname_part);
      l_table_row.c_pathname_part         := upper(p_c_pathname_part);
      l_table_row.e_pathname_part         := upper(p_e_pathname_part);
      l_table_row.f_pathname_part         := upper(p_f_pathname_part);
      l_table_row.dss_parameter_type_code := get_dss_parameter_type_code(p_dss_parameter_type);
      l_table_row.unit_id                 := p_units;
      l_table_row.time_zone_code          := cwms_util.get_time_zone_code(p_time_zone);
      l_table_row.tz_usage_code           := cwms_util.get_tz_usage_code(p_tz_usage);
      select *
        into l_table_row
        from at_dss_ts_spec
       where office_code             = l_table_row.office_code
         and a_pathname_part         = l_table_row.a_pathname_part
         and b_pathname_part         = l_table_row.b_pathname_part
         and c_pathname_part         = l_table_row.c_pathname_part
         and e_pathname_part         = l_table_row.e_pathname_part
         and f_pathname_part         = l_table_row.f_pathname_part
         and dss_parameter_type_code = l_table_row.dss_parameter_type_code
         and unit_id                 = l_table_row.unit_id
         and time_zone_code          = l_table_row.time_zone_code
         and tz_usage_code           = l_table_row.tz_usage_code;

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
   begin
      savepoint create_dss_ts_xchg_spec_start;

      cwms_ts.create_ts_code(
         l_cwms_ts_code,
         p_cwms_ts_id,
         null,
         null,
         null,
         'F',
         'T',
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
      l_dss_parameter_type_id := get_dss_parameter_type_id(l_dss_parameter_type_code);

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
      commit;
      
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
      l_dss_ts_xchg_code number;
      l_dss_ts_xchg_map  at_dss_ts_xchg_map%rowtype;
   begin
      l_dss_ts_xchg_code := create_dss_ts_xchg_spec(
            p_cwms_ts_id,
            p_dss_pathname,
            p_dss_parameter_type,
            p_units,
            p_time_zone,
            p_tz_usage,
            cwms_util.false_num,
            p_office_id);

      select *
        into l_dss_ts_xchg_map
        from at_dss_ts_xchg_map
       where dss_xchg_set_code = p_dss_xchg_set_code
         and dss_ts_xchg_code = l_dss_ts_xchg_code;
   exception
      when no_data_found then
         select cwms_seq.nextval into l_dss_ts_xchg_map.dss_ts_xchg_map_code from dual;
         insert 
           into at_dss_ts_xchg_map
         values l_dss_ts_xchg_map;
   end map_ts_in_xchg_set;

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
      where dss_ts_code not in
               (select distinct dss_ts_code 
                  from at_dss_ts_xchg_spec
                 where office_code = cwms_util.get_office_code(p_office_id));
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

show errors;
commit ;


create or replace package test_cwms_data_dissem as
--%suite(Test CWMS_DATA_DISSEM package routines)
--%rollback(manual)
--%beforeall(setup)
--%afterall(teardown)
--%test(Test group- and filter-based dissemenation routines)
procedure test_data_dissem;
procedure setup;
procedure teardown;
c_category_id               constant cwms_v_ts_cat_grp.ts_category_id%type := 'Data Dissemination';
c_internal_include_group_id constant cwms_v_ts_cat_grp.ts_group_id%type := 'CorpsNet Include List';
c_internal_exclude_group_id constant cwms_v_ts_cat_grp.ts_group_id%type := 'CorpsNet Exclude List';
c_external_include_group_id constant cwms_v_ts_cat_grp.ts_group_id%type := 'DMZ Include List';
c_external_exclude_group_id constant cwms_v_ts_cat_grp.ts_group_id%type := 'DMZ Exclude List';
c_destinations              constant cwms_t_str_tab := cwms_t_str_tab('CorpsNet', 'DMZ');
c_filtering_destinations    constant cwms_t_str_tab_tab := cwms_t_str_tab_tab(
                               cwms_t_str_tab(/*corpsnet*/'F',/*dmz*/'F'),
                               cwms_t_str_tab(/*corpsnet*/'F',/*dmz*/'T'),
                            -- cwms_t_str_tab(/*corpsnet*/'T',/*dmz*/'F'), -- illegal combination
                               cwms_t_str_tab(/*corpsnet*/'T',/*dmz*/'T'));
c_group_ids                 constant cwms_t_str_tab := cwms_t_str_tab(
                               c_internal_include_group_id,
                               c_internal_exclude_group_id,
                               c_external_include_group_id,
                               c_external_exclude_group_id);
c_in_group                  constant cwms_t_str_tab_tab := cwms_t_str_tab_tab(
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'F',/*ext incl*/'F',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'F',/*ext incl*/'F',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'F',/*ext incl*/'T',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'F',/*ext incl*/'T',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'T',/*ext incl*/'F',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'T',/*ext incl*/'F',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'T',/*ext incl*/'T',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'F',/*int excl*/'T',/*ext incl*/'T',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'F',/*ext incl*/'F',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'F',/*ext incl*/'F',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'F',/*ext incl*/'T',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'F',/*ext incl*/'T',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'T',/*ext incl*/'F',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'T',/*ext incl*/'F',/*ext excl*/'T'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'T',/*ext incl*/'T',/*ext excl*/'F'),
                               cwms_t_str_tab(/*int incl*/'T',/*int excl*/'T',/*ext incl*/'T',/*ext excl*/'T'));
c_ts_id                     constant cwms_v_ts_id.cwms_ts_id%type := 'Test-Data_Dissem.Code.Inst.1Hour.0.Test';
c_loc_id                    constant cwms_v_loc.location_id%type := cwms_util.split_text(c_ts_id, 1, '.');
c_office_id                 constant cwms_v_loc.db_office_id%type := '&&office_id';
end test_cwms_data_dissem;
/
create or replace package body test_cwms_data_dissem as
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   x_location_id_not_found exception;
   pragma exception_init(x_location_id_not_found, -20025);
begin
   begin
      cwms_loc.delete_location(
         p_location_id   => c_loc_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
      commit;
   exception
      when x_location_id_not_found then null;
   end;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => c_loc_id,
      p_db_office_id => c_office_id);
   commit;
end setup;
--------------------------------------------------------------------------------
-- procedure test_data_dissem
--------------------------------------------------------------------------------
procedure test_data_dissem
is
   l_seq          pls_integer := 0;
   l_ts_id        cwms_v_ts_id.cwms_ts_id%type;
   l_ts_code      cwms_v_ts_id.ts_code%type;
   l_crsr         sys_refcursor;
   l_ts_ids       cwms_t_str_tab;
   l_public_names cwms_t_str_tab;
   l_office_ids   cwms_t_str_tab;
   l_ts_codes     cwms_t_number_tab;
   l_office_codes cwms_t_number_tab;
   l_dest_dbs     cwms_t_str_tab;
   l_dest1        cwms_t_number_tab;
   l_dest2        cwms_t_number_tab;
   l_seq2         pls_integer;

   function in_group(p_group_id in varchar2, p_ts_id in varchar2) return boolean
   is
      l_count   pls_integer;
   begin
      select count(*)
        into l_count
        from cwms_v_ts_grp_assgn
       where category_id = c_category_id
         and group_id = p_group_id
         and ts_id = p_ts_id;
      return l_count != 0;
   end in_group;
begin
   dbms_output.put_line(null);
   l_dest1 := cwms_t_number_tab();
   l_dest1.extend(48);
   l_dest2 := cwms_t_number_tab();
   l_dest2.extend(48);
   for i in 1..l_dest2.count loop
      l_dest2(i) := 0;
   end loop;
   ---------------------------------------
   -- try invalid filtering combination --
   ---------------------------------------
   begin
      cwms_data_dissem.set_ts_filtering(/*corpsnet*/'T',/*dmz*/'F', c_office_id);
      cwms_err.raise('ERROR', 'Exected exception not raised.');
   exception
      when others then
         if instr(sqlerrm, 'The combination of CorpsNet Filtering TRUE and DMZ Filtering FALSE is not allowed.') = 0 then
            raise;
         end if;
   end;
   -----------------------------------------------------------
   -- try valid filtering and group membership combinations --
   -----------------------------------------------------------
   for i in 1..c_filtering_destinations.count loop
      cwms_data_dissem.set_ts_filtering(
         c_filtering_destinations(i)(1),
         c_filtering_destinations(i)(2),
         c_office_id);
      commit;
      for j in 1..c_in_group.count loop
         l_seq := l_seq + 1;
         ------------------------------
         -- get the time series code --
         ------------------------------
         l_ts_id := c_ts_id||'-'||trim(to_char(l_seq, '09'));
         cwms_ts.create_ts_code(
            p_ts_code    => l_ts_code,
            p_cwms_ts_id => l_ts_id,
            p_office_id  => c_office_id);
            l_ts_code := cwms_ts.get_ts_code(l_ts_id, c_office_id);
         dbms_output.put(
            to_char(l_seq, '09')||' - '
            ||case when cwms_data_dissem.is_filtering_to(c_destinations(1), c_office_id) then 'T' else 'F' end
            ||case when cwms_data_dissem.is_filtering_to(c_destinations(2), c_office_id) then 'T' else 'F' end
            ||' ');
         for k in 1..c_group_ids.count loop
            if c_in_group(j)(k) = 'T' then
               cwms_ts.assign_ts_group(
                  p_ts_category_id => c_category_id,
                  p_ts_group_id    => c_group_ids(k),
                  p_ts_id          => l_ts_id,
                  p_db_office_id   => c_office_id);
            else
               cwms_ts.unassign_ts_group(
                  p_ts_category_id => c_category_id,
                  p_ts_group_id    => c_group_ids(k),
                  p_ts_id          => l_ts_id,
                  p_db_office_id   => c_office_id);
            end if;
            commit;
            dbms_output.put(case when in_group(c_group_ids(k), l_ts_id) then 'T' else 'F' end);
         end loop;
         l_dest1(l_seq) := cwms_data_dissem.allowed_dest(l_ts_code);
         dbms_output.put(' ');
         dbms_output.put(case when cwms_data_dissem.allowed_to_corpsnet(l_ts_code) then 'T' else 'F' end);
         dbms_output.put(case when cwms_data_dissem.allowed_to_dmz(l_ts_code) then 'T' else 'F'end);
         dbms_output.put(' ');
         dbms_output.put(l_dest1(l_seq));
         dbms_output.put_line(null);
         case
         when not cwms_data_dissem.is_filtering_to('DMZ', c_office_id) then
            ---------------------------------------
            -- all data goes to corpsnet and dmz --
            ---------------------------------------
            ut.expect(cwms_data_dissem.is_filtering_to('CorpsNet', c_office_id)).to_be_false;
            ut.expect(cwms_data_dissem.allowed_to_corpsnet(l_ts_code)).to_be_true;
            ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_true;
            ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(2);
         when not cwms_data_dissem.is_filtering_to('Corpsnet', c_office_id) then
             -------------------------------
             -- all data goes to corpsnet --
             -------------------------------
            ut.expect(cwms_data_dissem.allowed_to_corpsnet(l_ts_code)).to_be_true;
            ------------------------------------
            -- only filtered data goes to dmz --
            ------------------------------------
            if in_group(c_external_include_group_id, l_ts_id) and not in_group(c_external_exclude_group_id, l_ts_id) and not in_group(c_internal_exclude_group_id, l_ts_id) then
               ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_true;
               ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(2);
            else
               ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_false;
               ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(1);
            end if;
         else
            -------------------------------------------------
            -- only filtered data goes to corpsnet and dmz --
            -------------------------------------------------
            if in_group(c_internal_include_group_id, l_ts_id) and not in_group(c_internal_exclude_group_id, l_ts_id) then
               ut.expect(cwms_data_dissem.allowed_to_corpsnet(l_ts_code)).to_be_true;
               if in_group(c_external_include_group_id, l_ts_id) and not in_group(c_external_exclude_group_id, l_ts_id) then
                  ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_true;
                  ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(2);
               else
                  ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_false;
                  ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(1);
               end if;
            else
               if in_group(c_external_include_group_id, l_ts_id) and not in_group(c_external_exclude_group_id, l_ts_id) and not in_group(c_internal_exclude_group_id, l_ts_id) then
                  ut.expect(cwms_data_dissem.allowed_to_corpsnet(l_ts_code)).to_be_true;
                  ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_true;
                  ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(2);
               else
                  ut.expect(cwms_data_dissem.allowed_to_corpsnet(l_ts_code)).to_be_false;
                  ut.expect(cwms_data_dissem.allowed_to_dmz(l_ts_code)).to_be_false;
                  ut.expect(cwms_data_dissem.allowed_dest(l_ts_code)).to_equal(0);
               end if;
            end if;
         end case;
      end loop;
      cwms_data_dissem.cat_ts_transfer(l_crsr, c_office_id);
      fetch l_crsr
       bulk collect
       into l_ts_ids,
            l_public_names,
            l_office_ids,
            l_ts_codes,
            l_office_codes,
            l_dest_dbs;
      close l_crsr;
      for m in 1..l_ts_ids.count loop
         l_seq2 := to_number(cwms_util.split_text(cwms_util.split_text(l_ts_ids(m), 6, '.'), 2, '-'));
         if l_seq2 between (i-1)*16+1 and i*16 then
            l_dest2(l_seq2) := case when l_dest_dbs(m) = 'CorpsNet' then 1 else 2 end;
            dbms_output.put_line(l_ts_ids(m)||chr(9)||l_dest_dbs(m));
         end if;
      end loop;
   end loop;
   for i in 1..l_dest1.count loop
      ut.expect(l_dest2(i)).to_equal(l_dest1(i));
   end loop;
end test_data_dissem;
end test_cwms_data_dissem;
/
show errors
drop package body &&cwms_schema..test_cwms_cat;
create or replace package &&cwms_schema..test_cwms_cat as

--%suite(Test CWMS_CAT package code)
--%rollback(manual)

--%test(Test whether CAT_TS_ID includes TS for inactive locations with time series created before being stored)
procedure test_cat_ts_id_with_create;
--%test(Test whether CAT_TS_ID includes TS for inactive locations with time series stored without separate creation)
procedure test_cat_ts_id_without_create;

--%beforeeach
procedure setup;
--%aftereach
procedure teardown;

type id_and_active_rec_t is record(
   id        varchar2(191),
   is_active varchar2(1)
);
type id_and_active_tab_t is table of id_and_active_rec_t;
type bool_by_id_t is table of boolean index by varchar2(191);
c_office_id  constant varchar2(16) := '&&office_id';
c_unit       constant varchar2(16) := 'n/a';
c_start_time constant date := date '2021-10-01';
c_time_zone  constant varchar2(28) := 'US/Central';
c_locations  constant id_and_active_tab_t := id_and_active_tab_t(
   id_and_active_rec_t('CwmsCatTestLoc1'        ,  'T'),
   id_and_active_rec_t('CwmsCatTestLoc1-WithSub1', 'T'),
   id_and_active_rec_t('CwmsCatTestLoc1-WithSub2', 'F'),
   id_and_active_rec_t('CwmsCatTestLoc2'         , 'F'),
   id_and_active_rec_t('CwmsCatTestLoc2-WithSub1', 'T'),
   id_and_active_rec_t('CwmsCatTestLoc2-WithSub2', 'F'));
c_timeseries  constant id_and_active_tab_t := id_and_active_tab_t(
   id_and_active_rec_t('.Code.Inst.1Hour.0.ver1', 'T'),
   id_and_active_rec_t('.Code.Inst.1Hour.0.ver2', 'F'));
c_ts_data     constant cwms_t_ztsv_array := cwms_t_ztsv_array(
   cwms_t_ztsv(c_start_time + 0 / 24, 1, 0),
   cwms_t_ztsv(c_start_time + 1 / 24, 1, 0),
   cwms_t_ztsv(c_start_time + 2 / 24, 1, 0),
   cwms_t_ztsv(c_start_time + 3 / 24, 1, 0),
   cwms_t_ztsv(c_start_time + 4 / 24, 1, 0),
   cwms_t_ztsv(c_start_time + 5 / 24, 1, 0));
v_active_locations  bool_by_id_t;
v_active_timeseries bool_by_id_t;
end test_cwms_cat;
/
show errors;

create or replace package body &&cwms_schema..test_cwms_cat
as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
   l_base_location varchar2(24);
   l_exists        varchar2(1);
begin
   for i in 1..c_locations.count loop
      l_base_location := cwms_util.split_text(c_locations(i).id, 1, '-');
      if c_locations(i).id = l_base_location then
         if c_locations(i).is_active = 'T' then
            v_active_locations(c_locations(i).id) := true;
         end if;
      elsif v_active_locations.exists(l_base_location) and c_locations(i).is_active = 'T' then
         v_active_locations(c_locations(i).id) := true;
      end if;
      begin
         select 'T'
           into l_exists
           from dual
          where exists (select location_id from cwms_v_loc where location_id = c_locations(i).id);
         if l_exists = 'T' then
            cwms_err.raise('LOCATION alreaedy exists: '||c_locations(i).id);
         end if;
      exception
         when no_data_found then null;
      end;
      cwms_loc.store_location(
         p_location_id  => c_locations(i).id,
         p_time_zone_id => c_time_zone,
         p_active       => c_locations(i).is_active,
         p_db_office_id => c_office_id);
   end loop;
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
begin
   for i in 1..c_locations.count loop
      begin
         cwms_loc.delete_location(
            p_location_id   => c_locations(i).id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => c_office_id);
      exception
         when others then null;
      end;
   end loop;
end teardown;
--------------------------------------------------------------------------------
-- procedure test_store_ts
--------------------------------------------------------------------------------
procedure test_store_ts(
   p_create_first in boolean
)
is
   l_cwms_ts_id        varchar2(191);
   l_location_id       varchar2(57);
begin
   if p_create_first then
      ----------------------------
      -- create the time series --
      ----------------------------
      for i in 1..c_locations.count loop
         for j in 1..c_timeseries.count loop
            l_cwms_ts_id := c_locations(i).id||c_timeseries(j).id;
            l_location_id := cwms_util.split_text(l_cwms_ts_id, 1, '.');
            if v_active_locations.exists(l_location_id) and c_timeseries(j).is_active = 'T' then
               v_active_timeseries(l_cwms_ts_id) := true;
            end if;
            cwms_ts.create_ts(
               p_cwms_ts_id  => l_cwms_ts_id,
               p_active_flag => c_timeseries(j).is_active,
               p_office_id   => c_office_id);
         end loop;
      end loop;
   end if;
   -----------------------
   -- store time series --
   -----------------------
   for i in 1..c_locations.count loop
      l_location_id := cwms_util.split_text(l_cwms_ts_id, 1, '.');
      for j in 1..c_timeseries.count loop
         l_cwms_ts_id := c_locations(i).id||c_timeseries(j).id;
         begin
            cwms_ts.zstore_ts(
               p_cwms_ts_id      => l_cwms_ts_id,
               p_units           => c_unit,
               p_timeseries_data => c_ts_data,
               p_store_rule      => cwms_util.replace_all,
               p_office_id       => c_office_id);
            if p_create_first and not v_active_timeseries.exists(l_cwms_ts_id) then
               -------------------------------------------------------------------------
               -- this should always succeed if we don't create the time series first --
               -- because the auto-creation in store-ts always creates an active ts   --
               -------------------------------------------------------------------------
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               if not v_active_timeseries.exists(l_cwms_ts_id) then
                  ut.expect(replace(dbms_utility.format_error_stack, chr(10), '|')).to_be_like('%Cannot store to inactive time series%', '\');
               end if;
         end;
      end loop;
   end loop;
end test_store_ts;
-- --------------------------------------------------------------------------------
-- -- procedure test_store_ts_with_create
-- --------------------------------------------------------------------------------
-- procedure test_store_ts_with_create
-- is
-- begin
--    test_store_ts(true);
-- end test_store_ts_with_create;
-- --------------------------------------------------------------------------------
-- -- procedure test_store_ts_with_create
-- --------------------------------------------------------------------------------
-- procedure test_store_ts_without_create
-- is
-- begin
--    test_store_ts(false);
-- end test_store_ts_without_create;
--------------------------------------------------------------------------------
-- procedure test_cat_ts_id
--------------------------------------------------------------------------------
procedure test_cat_ts_id(
   p_create in boolean
)
is
   l_crsr              sys_refcursor;
   l_office_ids        cwms_t_str_tab;
   l_base_location_ids cwms_t_str_tab;
   l_cwms_ts_ids       cwms_t_str_tab;
   l_offsets           cwms_t_number_tab;
   l_lrts_timezone_ids cwms_t_str_tab;
   l_active_flags      cwms_t_str_tab;
   l_user_privileges   cwms_t_number_tab;
begin
   ---------------------------
   -- store the time series --
   ---------------------------
   test_store_ts(p_create);
   -----------------------------
   -- catalog the time series --
   -----------------------------
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => '*',
      p_db_office_id        => c_office_id);
   fetch l_crsr
    bulk collect
    into l_office_ids,
         l_base_location_ids,
         l_cwms_ts_ids,
         l_offsets,
         l_lrts_timezone_ids,
         l_active_flags,
         l_user_privileges;
   close l_crsr;
   ut.expect(l_cwms_ts_ids.count).to_equal(c_locations.count * c_timeseries.count);
   for i in 1..l_cwms_ts_ids.count loop
      if p_create then
         -----------------------------
         -- use v_active_timeseries --
         -----------------------------
         if v_active_timeseries.exists(l_cwms_ts_ids(i)) then
            ut.expect(l_active_flags(i)).to_equal('T');
         else
            ut.expect(l_active_flags(i)).to_equal('F');
         end if;
      else
         -------------------------------------------------------------------------------------------------
         -- use v_active_locations since STORE_TS always creates an active time seires if it creates it --
         -------------------------------------------------------------------------------------------------
         if v_active_locations.exists(cwms_util.split_text(l_cwms_ts_ids(i), 1, '.')) then
            ut.expect(l_active_flags(i)).to_equal('T');
         else
            ut.expect(l_active_flags(i)).to_equal('F');
         end if;
      end if;
   end loop;
end test_cat_ts_id;
--------------------------------------------------------------------------------
-- test_cat_ts_id_with_create
--------------------------------------------------------------------------------
procedure test_cat_ts_id_with_create
is
begin
   test_cat_ts_id(true);
end test_cat_ts_id_with_create;
--------------------------------------------------------------------------------
-- test_cat_ts_id_without_create
--------------------------------------------------------------------------------
procedure test_cat_ts_id_without_create
is
begin
   test_cat_ts_id(false);
end test_cat_ts_id_without_create;

end test_cwms_cat;
/
show errors;

grant execute on test_cwms_cat to cwms_user;
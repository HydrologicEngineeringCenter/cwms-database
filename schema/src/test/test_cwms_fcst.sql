create or replace package test_cwms_fcst as

--%suite(Test cwms_fcst package code)

--%beforeeach(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test store, catalog, retrieve, and delete operations for new style forecast specifications)
procedure test_fcst_spec_ops;
--%test(Test store, catalog, retrieve, and delete operations for new style forecasts)
procedure test_fcst_inst_ops;

procedure setup;
procedure teardown;

c_iso_format      constant varchar2(23)                       := 'yyyy-mm-dd"T"hh24:mi:ss';
c_iso_format_tz   constant varchar2(29)                       := 'yyyy-mm-dd"T"hh24:mi:sstzhtzm';
c_office_id       constant cwms_office.office_id%type         := '&&office_id';
c_location_id     constant at_cwms_ts_id.location_id%type     := 'FcstTestLoc';
c_time_zone_id    constant cwms_time_zone.time_zone_name%type := 'US/Pacific';
c_fcst_spec_id    constant at_fcst_spec.fcst_spec_id%type     := 'TEST';
c_fcst_designator constant at_fcst_spec.fcst_designator%type  := 'Designator';
c_fcst_date       constant date            := to_date('2024-11-22T08:00:00', c_iso_format);
c_end_date        constant date            := c_fcst_date + 7;
c_issue_date      constant date            := to_date('2024-11-22T12:00:00', c_iso_format);
c_max_age         constant binary_integer  := 12;
c_fcst_notes      constant varchar2(32767) := 'Questionable stage reading at Elm Stree Bridge';
c_fcst_info       constant varchar2(32767) := '{"startTime": "<start>", "endTime": "<end>", "userId": "<user>", "complex": {"a":1,"b":[123],"c":true,"d":false,"e":null}}';
end test_cwms_fcst;
/
show errors
create or replace package body test_cwms_fcst as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_time_zone_id => c_time_zone_id,
      p_active       => 'T',
      p_db_office_id => c_office_id);
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   location_id_not_found exception;
   item_does_not_exist   exception;
   pragma exception_init(location_id_not_found, -20025);
   pragma exception_init(item_does_not_exist, -20034);
begin
   begin
      cwms_fcst.delete_fcst_spec(
         p_fcst_spec_id     => c_fcst_spec_id,
         p_fcst_designator  => c_fcst_designator,
         p_delete_action    => cwms_util.delete_all,
         p_office_id        => c_office_id);
   exception
      when item_does_not_exist then null;
   end;
   begin
      cwms_loc.delete_location(c_location_id, cwms_util.delete_all, c_office_id);
   exception
      when location_id_not_found then null;
   end;
   commit;
end teardown;
--------------------------------------------------------------------------------
-- private function sort_text_recs
--------------------------------------------------------------------------------
function sort_text_recs(p_input clob) return clob
is
   l_result clob;
begin
   if p_input is null then return null; end if;
   for c in (select column_value as rec from (cwms_util.split_text(p_input, chr(10))) order by 1) loop
      l_result := l_result||chr(10)||c.rec;
   end loop;
   return substr(l_result, 1);
end sort_text_recs;
--------------------------------------------------------------------------------
-- private function clob_to_blob
--------------------------------------------------------------------------------
function clob_to_blob(p_clob in clob) return blob
is
   l_src_offset integer := 1;
   l_dst_offset integer := 1;
   l_lang_ctx   integer := dbms_lob.default_lang_ctx;
   l_warning    integer;
   l_blob       blob;
begin
   if p_clob is null then
      return null;
   end if;
   dbms_lob.createtemporary(l_blob, true);
   dbms_lob.converttoblob(
      dest_lob     => l_blob,
      src_clob     => p_clob,
      amount       => dbms_lob.lobmaxsize,
      dest_offset  => l_dst_offset,
      src_offset   => l_src_offset,
      blob_csid    => dbms_lob.default_csid,
      lang_context => l_lang_ctx,
      warning      => l_warning);
   return l_blob;
end clob_to_blob;
--------------------------------------------------------------------------------
-- private function blob_to_clob
--------------------------------------------------------------------------------
function blob_to_clob(p_blob in blob) return clob
is
   l_src_offset integer := 1;
   l_dst_offset integer := 1;
   l_lang_ctx   integer := dbms_lob.default_lang_ctx;
   l_warning    integer;
   l_clob       clob;
begin
   if p_blob is null then
      return null;
   end if;
   dbms_lob.createtemporary(l_clob, true);
   dbms_lob.converttoclob(
      dest_lob     => l_clob,
      src_blob     => p_blob,
      amount       => dbms_lob.lobmaxsize,
      dest_offset  => l_dst_offset,
      src_offset   => l_src_offset,
      blob_csid    => dbms_lob.default_csid,
      lang_context => l_lang_ctx,
      warning      => l_warning);
   return l_clob;
end blob_to_clob;
---------------------------------------------------------------------------------
-- procedure test_fcst_spec_ops
---------------------------------------------------------------------------------
procedure test_fcst_spec_ops
is
   l_count              binary_integer;
   l_count2             binary_integer;
   l_crsr               sys_refcursor;
   l_office_id          cwms_office.office_id%type;
   l_fcst_spec_id       at_fcst_spec.fcst_spec_id%type;
   l_fcst_designator    at_fcst_spec.fcst_designator%type;
   l_entity_id          at_entity.entity_id%type;
   l_entity_id_out      at_entity.entity_id%type;
   l_entity_name        at_entity.entity_name%type;
   l_description        at_fcst_spec.description%type;
   l_description_out    at_fcst_spec.description%type;
   l_location_id        at_cwms_ts_id.location_id%type;
   l_location_id_out    at_cwms_ts_id.location_id%type;
   l_timeseries_ids     clob;
   l_timeseries_ids_out clob;
   l_timeseries_id      at_cwms_ts_id.cwms_ts_id%type;
   l_tsid_crsr          sys_refcursor;
begin
   dbms_output.enable(null);
   for has_designator in 0..1 loop
      l_fcst_designator := case when has_designator = 1 then c_fcst_designator else null end;
      for has_location in 0..1 loop
         l_location_id := case when has_location = 1 then c_location_id else null end;
         for has_timeseries in 0..1 loop
            if has_timeseries = 1 then
               l_timeseries_ids := ''
                  ||c_location_id||'.Stage.Inst.1Hour.0.Fcst'
                  ||chr(10)
                  ||c_location_id||'.Flow.Inst.1Hour.0.Fcst';
               for rec in (select column_value as tsid from table(cwms_util.split_text(l_timeseries_ids, chr(10)))) loop
                  cwms_ts.zstore_ts(
                     p_cwms_ts_id      => rec.tsid,
                     p_units           => case when instr(rec.tsid, 'Stage') > 1 then 'ft' else 'cfs' end,
                     p_timeseries_data => cwms_t_ztsv_array(),
                     p_store_rule      => cwms_util.replace_all,
                     p_version_date    => cwms_util.non_versioned,
                     p_office_id       => c_office_id);
               end loop;
            else
               l_timeseries_ids := null;
            end if;
            ----------------
            -- store spec --
            ----------------
            dbms_output.put_line('    |');
            dbms_output.put_line('    Verifying operation of Cwms_Fcst.Store_Fcst_Spec');
            dbms_output.put_line('        Has designator  = '||case when has_designator = 1 then 'True' else 'False' end);
            dbms_output.put_line('        Has location    = '||case when has_location = 1 then 'True' else 'False' end);
            dbms_output.put_line('        Has time series = '||case when has_timeseries = 1 then 'True' else 'False' end);
            cwms_fcst.store_fcst_spec(
               p_fcst_spec_id    => c_fcst_spec_id,
               p_fcst_designator => l_fcst_designator,
               p_entity_id       => 'CE'||c_office_id,
               p_description     => 'Test forecast spec',
               p_location_id     => l_location_id,
               p_timeseries_ids  => l_timeseries_ids,
               p_fail_if_exists  => 'F',
               p_ignore_nulls    => 'T',
               p_office_id       => c_office_id);
            begin
               cwms_fcst.store_fcst_spec(
                  p_fcst_spec_id    => c_fcst_spec_id,
                  p_fcst_designator => l_fcst_designator,
                  p_entity_id       => 'CE'||c_office_id,
                  p_description     => 'Test forecast spec',
                  p_location_id     => l_location_id,
                  p_timeseries_ids  => l_timeseries_ids,
                  p_fail_if_exists  => 'T',
                  p_ignore_nulls    => 'T',
                  p_office_id       => c_office_id);
               cwms_err.raise('ERROR', 'Expected exception not raised');
            exception
               when others then
                  ut.expect(dbms_utility.format_error_stack).to_be_like('%Forecast specification%already exists%');
            end;
            ---------------------------------
            -- check cwms_v_fcst_spec view --
            ---------------------------------
            dbms_output.put_line('    Verifying content of Cwms_V_Fcst_Spec view');
            l_count := 0;
            if has_designator = 1 then
               for rec in (select *
                           from cwms_v_fcst_spec
                           where office_id = c_office_id
                              and fcst_spec_id = c_fcst_spec_id
                              and fcst_designator = c_fcst_designator
                        )
               loop
                  l_count := l_count + 1;
                  ut.expect(rec.office_id).to_equal(c_office_id);
                  ut.expect(rec.fcst_spec_id).to_equal(c_fcst_spec_id);
                  ut.expect(rec.fcst_designator).to_equal(c_fcst_designator);
                  ut.expect(rec.entity_id).to_equal('CE'||c_office_id);
               end loop;
            else
               for rec in (select *
                           from cwms_v_fcst_spec
                           where office_id = c_office_id
                              and fcst_spec_id = c_fcst_spec_id
                              and fcst_designator is null
                        )
               loop
                  l_count := l_count + 1;
                  ut.expect(rec.office_id).to_equal(c_office_id);
                  ut.expect(rec.fcst_spec_id).to_equal(c_fcst_spec_id);
                  ut.expect(rec.fcst_designator).to_be_null;
                  ut.expect(rec.entity_id).to_equal('CE'||c_office_id);
               end loop;
            end if;
            ut.expect(l_count).to_equal(1);
            -------------------------------------
            -- check cwms_v_fcst_location view --
            -------------------------------------
            dbms_output.put_line('    Verifying content of Cwms_V_Fcst_Location view');
            if has_designator = 1 then
               select count(*)
               into l_count
               from cwms_v_fcst_location
               where office_id = c_office_id
                  and fcst_spec_id = c_fcst_spec_id
                  and fcst_designator = c_fcst_designator;
               if has_location = 1 then
                  ut.expect(l_count).to_equal(1);
                  select location_id
                  into l_location_id_out
                  from cwms_v_fcst_location
                  where office_id = c_office_id
                     and fcst_spec_id = c_fcst_spec_id
                     and fcst_designator = c_fcst_designator;
                  ut.expect(l_location_id_out).to_equal(c_location_id);
               else
                  ut.expect(l_count).to_equal(0);
               end if;
            else
               select count(*)
               into l_count
               from cwms_v_fcst_location
               where office_id = c_office_id
                  and fcst_spec_id = c_fcst_spec_id
                  and fcst_designator is null;
               if has_location = 1 then
                  ut.expect(l_count).to_equal(1);
                  select location_id
                  into l_location_id_out
                  from cwms_v_fcst_location
                  where office_id = c_office_id
                     and fcst_spec_id = c_fcst_spec_id
                     and fcst_designator is null;
                  ut.expect(l_location_id_out).to_equal(c_location_id);
               else
                  ut.expect(l_count).to_equal(0);
               end if;
            end if;
            ----------------------------------------
            -- check cwms_v_fcst_time_series view --
            ----------------------------------------
            dbms_output.put_line('    Verifying content of Cwms_V_Fcst_Time_Series view');
            if has_designator = 1 then
               select count(*)
               into l_count
               from cwms_v_fcst_time_series
               where office_id = c_office_id
                  and fcst_spec_id = c_fcst_spec_id
                  and fcst_designator = c_fcst_designator;
               if has_timeseries = 1 then
                  ut.expect(l_count).to_equal(2);
                  l_timeseries_ids_out := null;
                  for rec in (select cwms_ts_id
                              from cwms_v_fcst_time_series
                              where office_id = c_office_id
                                 and fcst_spec_id = c_fcst_spec_id
                                 and fcst_designator = c_fcst_designator
                           )
                  loop
                     l_timeseries_ids_out := l_timeseries_ids_out || rec.cwms_ts_id || chr(10);
                  end loop;
                  ut.expect(sort_text_recs(trim(chr(10) from l_timeseries_ids_out))).to_equal(sort_text_recs(trim(chr(10) from l_timeseries_ids)));
               else
                  ut.expect(l_count).to_equal(0);
               end if;
            else
               select count(*)
               into l_count
               from cwms_v_fcst_time_series
               where office_id = c_office_id
                  and fcst_spec_id = c_fcst_spec_id
                  and fcst_designator is null;
               if has_timeseries = 1 then
                  ut.expect(l_count).to_equal(2);
                  l_timeseries_ids_out := null;
                  for rec in (select cwms_ts_id
                              from cwms_v_fcst_time_series
                              where office_id = c_office_id
                                 and fcst_spec_id = c_fcst_spec_id
                                 and fcst_designator is null
                           )
                  loop
                     l_timeseries_ids_out := l_timeseries_ids_out || rec.cwms_ts_id || chr(10);
                  end loop;
                  ut.expect(sort_text_recs(trim(chr(10) from l_timeseries_ids_out))).to_equal(sort_text_recs(trim(chr(10) from l_timeseries_ids)));
               else
                  ut.expect(l_count).to_equal(0);
               end if;
            end if;
            -------------------
            -- check catalog --
            -------------------
            dbms_output.put_line('    Verifying operation of Cwms_Fcst.Cat_Fcst_Spec');
            cwms_fcst.cat_fcst_spec(
               p_cursor         => l_crsr,
               p_office_id_mask => c_office_id);
            l_count := 0;
            loop
               fetch l_crsr
               into l_office_id,
                     l_fcst_spec_id,
                     l_fcst_designator,
                     l_entity_id,
                     l_entity_name,
                     l_description,
                     l_tsid_crsr;
               exit when l_crsr%notfound;
               l_count := l_count + 1;
               ut.expect(l_office_id).to_equal(c_office_id);
               ut.expect(l_fcst_spec_id).to_equal(c_fcst_spec_id);
               if has_designator = 1 then
                  ut.expect(l_fcst_designator).to_equal(c_fcst_designator);
               else
                  ut.expect(l_fcst_designator).to_be_null;
               end if;
               ut.expect(l_entity_id).to_equal('CE'||c_office_id);
               if has_timeseries = 1 then
                  l_count2 := 0;
                  loop
                     fetch l_tsid_crsr into l_timeseries_id;
                     ut.expect(instr(l_timeseries_ids, l_timeseries_id)).to_be_greater_or_equal(1);
                     exit when l_tsid_crsr%notfound;
                     l_count2 := l_count2 + 1;
                  end loop;
                  ut.expect(l_count2).to_equal(cwms_util.split_text(l_timeseries_ids, chr(10)).count);
               else
                  ut.expect(nvl(l_tsid_crsr%notfound, true)).to_equal(true);
               end if;
            end loop;
            close l_crsr;
            ut.expect(l_count).to_equal(1);
            -------------------
            -- retrieve spec --
            -------------------
            dbms_output.put_line('    Verifying operation of Cwms_Fcst.Retrieve_Fcst_Spec');
            cwms_fcst.retrieve_fcst_spec(
               p_entity_id       => l_entity_id_out,
               p_description     => l_description_out,
               p_location_id     => l_location_id_out,
               p_timeseries_ids  => l_timeseries_ids_out,
               p_fcst_spec_id    => c_fcst_spec_id,
               p_fcst_designator => l_fcst_designator,
               p_office_id       => c_office_id);
            ut.expect(l_entity_id_out).to_equal(l_entity_id);
            ut.expect(l_description_out).to_equal(l_description);
            if has_location = 1 then
               ut.expect(l_location_id_out).to_equal(l_location_id);
            else
               ut.expect(l_location_id_out).to_be_null;
            end if;
            if has_timeseries = 1 then
               ut.expect(sort_text_recs(l_timeseries_ids_out)).to_equal(sort_text_recs(l_timeseries_ids));
            else
               ut.expect(l_timeseries_ids_out).to_be_null;
            end if;
            -----------------
            -- delete spec --
            -----------------
            dbms_output.put_line('    Verifying operation of Cwms_Fcst.Delete_Fcst_Spec');
            cwms_fcst.delete_fcst_spec(
               p_fcst_spec_id    => c_fcst_spec_id,
               p_fcst_designator => l_fcst_designator,
               p_delete_action   => cwms_util.delete_key,
               p_office_id       => c_office_id);
            -----------------
            -- check views --
            -----------------
            l_count := 0;
            select count(*)
            into l_count
            from cwms_v_fcst_spec
            where office_id = c_office_id
               and fcst_spec_id = c_fcst_spec_id
               and fcst_designator = l_fcst_designator;
            ut.expect(l_count).to_equal(0);
            select count(*)
            into l_count
            from cwms_v_fcst_location
            where office_id = c_office_id
               and fcst_spec_id = c_fcst_spec_id
               and fcst_designator = l_fcst_designator;
            ut.expect(l_count).to_equal(0);
            select count(*)
            into l_count
            from cwms_v_fcst_time_series
            where office_id = c_office_id
               and fcst_spec_id = c_fcst_spec_id
               and fcst_designator = l_fcst_designator;
            ut.expect(l_count).to_equal(0);
            -------------------
            -- check catalog --
            -------------------
            cwms_fcst.cat_fcst_spec(
               p_cursor         => l_crsr,
               p_office_id_mask => c_office_id);
            l_count := 0;
            loop
               fetch l_crsr
               into l_office_id,
                     l_fcst_spec_id,
                     l_fcst_designator,
                     l_entity_id,
                     l_entity_name,
                     l_description,
                     l_tsid_crsr;
               exit when l_crsr%notfound;
               l_count := l_count + 1;
            end loop;
            close l_crsr;
            ut.expect(l_count).to_equal(0);
         end loop;
      end loop;
   end loop;
end test_fcst_spec_ops;
---------------------------------------------------------------------------------
-- procedure test_fcst_inst_ops
---------------------------------------------------------------------------------
procedure test_fcst_inst_ops
is
   l_count              binary_integer;
   l_entity_id          at_entity.entity_id%type := 'CE'||c_office_id;
   l_description        at_fcst_spec.description%type := 'Test forecast spec';
   l_timeseries_ids     clob;
   l_timeseries_ids_out clob;
   l_fcst_info          varchar2(32767);
   l_client_userid      varchar2(100);
   l_file_contents      clob;
   l_blob_file          cwms_t_blob_file;
   l_fcst_date_utc      date := cwms_util.change_timezone(c_fcst_date, c_time_zone_id, 'UTC');
   l_issue_date_utc     date := cwms_util.change_timezone(c_issue_date, c_time_zone_id, 'UTC');
   l_inst_rec           cwms_v_fcst_inst%rowtype;
   l_info_rec           cwms_v_fcst_info%rowtype;
   l_json_obj           json_object_t;
   l_json_obj2          json_object_t;
   l_keys               json_key_list;
   l_keys2              json_key_list;
   l_value              json_element_t;
   l_crsr               sys_refcursor;
   l_office_id          varchar2(16);
   l_fcst_spec_id       varchar2(256);
   l_fcst_designator    varchar2(256);
   l_time_zone          varchar2(28);
   l_fcst_date          date;
   l_issue_date         date;
   l_max_age            integer;
   l_valid              varchar2(1);
   l_info               varchar2(32767);
   l_notes              varchar2(256);
   l_has_file           varchar2(1);
   l_file_name          varchar2(256);
   l_file_size          integer;
   l_file_media_type    varchar2(256);
   l_info_crsr          sys_refcursor;
   l_count2             binary_integer;
   l_key                varchar2(32767);
   l_value_str          varchar2(32767);
begin
   ------------------------
   -- create time series --
   ------------------------
   l_timeseries_ids := ''
      ||c_location_id||'.Stage.Inst.1Hour.0.Fcst'
      ||chr(10)
      ||c_location_id||'.Flow.Inst.1Hour.0.Fcst';
   for rec in (select column_value as tsid from table(cwms_util.split_text(l_timeseries_ids, chr(10)))) loop
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => rec.tsid,
         p_units           => case when instr(rec.tsid, 'Stage') > 1 then 'ft' else 'cfs' end,
         p_timeseries_data => cwms_t_ztsv_array(),
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);
   end loop;
   ----------------
   -- store spec --
   ----------------
   cwms_fcst.store_fcst_spec(
      p_fcst_spec_id    => c_fcst_spec_id,
      p_fcst_designator => c_fcst_designator,
      p_entity_id       => l_entity_id,
      p_description     => l_description,
      p_location_id     => c_location_id,
      p_timeseries_ids  => l_timeseries_ids,
      p_fail_if_exists  => 'F',
      p_ignore_nulls    => 'T',
      p_office_id       => c_office_id);
   dbms_lob.createtemporary(l_file_contents, true);
   for rec in (select text from user_source where name = 'CWMS_FCST' and type = 'PACKAGE' order by line) loop
      l_file_contents := l_file_contents || rec.text;
   end loop;
   for has_info in 0..1 loop
      ---------------------------
      -- set the forecast info --
      ---------------------------
      if has_info = 1 then
         select distinct
               osuser
         into l_client_userid
         from v$session
         where audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
         l_fcst_info := c_fcst_info;
         l_fcst_info := replace(l_fcst_info, '<start>', to_char(from_tz(cast(c_fcst_date as timestamp), (c_time_zone_id)), c_iso_format_tz));
         l_fcst_info := replace(l_fcst_info, '<end>', to_char(from_tz(cast(c_end_date as timestamp), (c_time_zone_id)), c_iso_format_tz));
         l_fcst_info := replace(l_fcst_info, '<user>', l_client_userid);
      else
         l_fcst_info := null;
      end if;
      for has_file in 0..1 loop
      -----------------------
      -- set the blob file --
      -----------------------
         if has_file = 1 then
            l_blob_file := cwms_t_blob_file(
               filename     => 'fcst.txt',
               media_type   => 'text/plain',
               quality_code => 0,
               the_blob     => clob_to_blob(l_file_contents));
         else
            l_blob_file := null;
         end if;
         dbms_output.put_line('    |');
         dbms_output.put_line('    Verifying operation of Cwms_Fcst.Store_Fcst');
         dbms_output.put_line('        Has info = '||case when has_info = 1 then 'True' else 'False' end);
         dbms_output.put_line('        Has file = '||case when has_file = 1 then 'True' else 'False' end);
         ----------------
         -- store inst --
         ----------------
         cwms_fcst.store_fcst(
            p_fcst_spec_id       => c_fcst_spec_id,
            p_fcst_designator    => c_fcst_designator,
            p_forecast_date_time => c_fcst_date,
            p_issue_date_time    => c_issue_date,
            p_time_zone          => c_time_zone_id,
            p_max_age            => c_max_age,
            p_notes              => c_fcst_notes,
            p_fcst_info          => l_fcst_info,
            p_fcst_file          => l_blob_file,
            p_fail_if_exists     => 'T' ,
            p_ignore_nulls       => 'F' ,
            p_office_id          => c_office_id);
         commit;
         begin
            cwms_fcst.store_fcst(
               p_fcst_spec_id       => c_fcst_spec_id,
               p_fcst_designator    => c_fcst_designator,
               p_forecast_date_time => c_fcst_date,
               p_issue_date_time    => c_issue_date,
               p_time_zone          => c_time_zone_id,
               p_max_age            => c_max_age,
               p_notes              => c_fcst_notes,
               p_fcst_info          => case when has_info = 1 then l_fcst_info else null end,
               p_fcst_file          => case when has_file = 1 then l_blob_file else null end,
               p_fail_if_exists     => 'T' ,
               p_ignore_nulls       => 'F' ,
               p_office_id          => c_office_id);
            cwms_err.raise('ERROR', 'Expected exception not raised');
         exception
            when others then
               ut.expect(dbms_utility.format_error_stack).to_be_like('%Forecast instance%already exists%');
         end;
         ---------------------------------
         -- check cwms_v_fcst_inst view --
         ---------------------------------
         dbms_output.put_line('    Verifying content of Cwms_V_Fcst_Inst view');
         select *
         into l_inst_rec
         from cwms_v_fcst_inst
         where office_id = c_office_id
            and fcst_spec_id = c_fcst_spec_id
            and fcst_designator = c_fcst_designator
            and fcst_date_time_utc = l_fcst_date_utc
            and issue_date_time_utc = l_issue_date_utc;
         ut.expect(l_inst_rec.valid_hours).to_equal(c_max_age);
         if (sysdate - l_issue_date_utc) * 24 > l_inst_rec.valid_hours then
            ut.expect(l_inst_rec.valid).to_equal('F');
         else
            ut.expect(l_inst_rec.valid).to_equal('T');
         end if;
         if has_file = 1 then
            ut.expect(l_inst_rec.file_name).to_equal('fcst.txt');
            ut.expect(l_inst_rec.file_size).to_equal(dbms_lob.getlength(l_file_contents));
            ut.expect(l_inst_rec.file_media_type).to_equal('text/plain');
         else
            ut.expect(l_inst_rec.file_name).to_be_null;
            ut.expect(l_inst_rec.file_size).to_be_null;
            ut.expect(l_inst_rec.file_media_type).to_be_null;
         end if;
         ut.expect(l_inst_rec.notes).to_equal(c_fcst_notes);
         -------------------------------------
         -- check the cwms_v_fcst_info view --
         -------------------------------------
         dbms_output.put_line('    Verifying content of Cwms_V_Fcst_Info view');
         select count(*)
         into l_count
         from cwms_v_fcst_info
         where office_id = c_office_id
            and fcst_spec_id = c_fcst_spec_id
            and fcst_designator = c_fcst_designator
            and fcst_date_time_utc = l_fcst_date_utc
            and issue_date_time_utc = l_issue_date_utc;
         if has_info = 1 then
            l_json_obj := json_object_t.parse(l_fcst_info);
            l_keys := l_json_obj.get_keys;
            ut.expect(l_count).to_equal(l_keys.count);
            for i in 1..l_keys.count loop
               select *
               into l_info_rec
               from cwms_v_fcst_info
               where office_id = c_office_id
                  and fcst_spec_id = c_fcst_spec_id
                  and fcst_designator = c_fcst_designator
                  and fcst_date_time_utc = l_fcst_date_utc
                  and issue_date_time_utc = l_issue_date_utc
                  and key = l_keys(i);
               ut.expect(l_info_rec.value).to_equal(l_json_obj.get(l_keys(i)).to_string());
            end loop;
         else
            ut.expect(l_count).to_equal(0);
         end if;
         -------------------
         -- check catalog --
         -------------------
         dbms_output.put_line('    Verifying operation of Cwms_Fcst.Cat_Fcst');
         l_crsr := cwms_fcst.cat_fcst_f (
            p_fcst_spec_id_mask	    => c_fcst_spec_id,
            p_fcst_designator_mask	 => c_fcst_designator,
            p_min_forecast_date_time => l_fcst_date_utc,
            p_max_forecast_date_time => l_fcst_date_utc,
            p_min_issue_date_time	 => l_issue_date_utc,
            p_max_issue_date_time	 => l_issue_date_utc,
            p_time_zone	             => 'UTC',
            p_valid_forecasts_only	 => 'F',
            p_key_mask	             => '*' ,
            p_value_mask	          => '*' ,
            p_office_id_mask	       => c_office_id);
         l_count := 0;
         loop
            fetch l_crsr
             into l_office_id,
                  l_fcst_spec_id,
                  l_fcst_designator,
                  l_time_zone,
                  l_fcst_date,
                  l_issue_date,
                  l_max_age,
                  l_valid,
                  l_notes,
                  l_file_name,
                  l_file_size,
                  l_file_media_type,
                  l_info_crsr;
            exit when l_crsr%notfound;
            l_count := l_count + 1;
            ut.expect(l_office_id).to_equal(c_office_id);
            ut.expect(l_fcst_spec_id).to_equal(c_fcst_spec_id);
            ut.expect(l_fcst_designator).to_equal(c_fcst_designator);
            ut.expect(l_time_zone).to_equal('UTC');
            ut.expect(l_fcst_date).to_equal(l_fcst_date_utc);
            ut.expect(l_issue_date).to_equal(l_issue_date_utc);
            ut.expect(l_max_age).to_equal(c_max_age);
            ut.expect(l_valid).to_equal(case when (sysdate - l_issue_date) * 24 > l_max_age then 'F' else 'T' end);
            ut.expect(l_notes).to_equal(c_fcst_notes);
            if has_file = 1 then
               ut.expect(l_file_name).to_equal('fcst.txt');
               ut.expect(l_file_size).to_equal(dbms_lob.getlength(l_file_contents));
               ut.expect(l_file_media_type).to_equal('text/plain');
            else
               ut.expect(l_file_name).to_be_null;
               ut.expect(l_file_size).to_be_null;
               ut.expect(l_file_media_type).to_be_null;
            end if;
            l_count2 := 0;
            if has_info = 1 then
               l_json_obj := json_object_t.parse(l_fcst_info);
               l_keys := l_json_obj.get_keys;
               loop
                  fetch l_info_crsr
                    into l_key,
                         l_value_str;
                  exit when l_info_crsr%notfound;
                  l_count2 := l_count2 + 1;
                  ut.expect(l_value_str).to_equal(l_json_obj.get(l_key).to_string());
               end loop;
               ut.expect(l_count2).to_equal(l_keys.count);
            else
               ut.expect(l_count2).to_equal(0);
            end if;
         end loop;
         ut.expect(l_count).to_equal(1);
         -------------------
         -- retrieve inst --
         -------------------
         dbms_output.put_line('    Verifying operation of Cwms_Fcst.Retrieve_Fcst');
         l_blob_file := null;
         -- don't retrieve file
         cwms_fcst.retrieve_fcst(
            p_max_age	         => l_max_age,
            p_notes	            => l_notes,
            p_fcst_info	         => l_info,
            p_has_file	         => l_has_file,
            p_timeseries_ids     => l_timeseries_ids_out,
            p_fcst_file	         => l_blob_file,
            p_fcst_spec_id	      => c_fcst_spec_id,
            p_fcst_designator	   => c_fcst_designator,
            p_forecast_date_time	=> l_fcst_date_utc,
            p_issue_date_time	   => l_issue_date_utc,
            p_time_zone	         => 'UTC',
            p_retrieve_file	   => 'F',
            p_office_id	         => c_office_id);
         ut.expect(l_blob_file is null).to_be_true;
         -- retrieve file (if exists)
         cwms_fcst.retrieve_fcst(
            p_max_age	         => l_max_age,
            p_notes	            => l_notes,
            p_fcst_info	         => l_info,
            p_has_file	         => l_has_file,
            p_timeseries_ids     => l_timeseries_ids_out,
            p_fcst_file	         => l_blob_file,
            p_fcst_spec_id	      => c_fcst_spec_id,
            p_fcst_designator	   => c_fcst_designator,
            p_forecast_date_time	=> l_fcst_date_utc,
            p_issue_date_time	   => l_issue_date_utc,
            p_time_zone	         => 'UTC',
            p_retrieve_file	   => 'T',
            p_office_id	         => c_office_id);
         ut.expect(l_max_age).to_equal(c_max_age);
         ut.expect(l_notes).to_equal(c_fcst_notes);
         if has_info = 1 then
            l_json_obj2 := json_object_t.parse(l_info);
            l_keys2 := l_json_obj2.get_keys();
            ut.expect(l_keys2.count).to_equal(l_keys.count);
            for i in 1..l_keys2.count loop
               ut.expect(l_json_obj2.get(l_keys2(i)).to_string).to_equal(l_json_obj.get(l_keys2(i)).to_string);
            end loop;
         else
            ut.expect(l_info).to_be_null;
         end if;
         if has_file = 1 then
            ut.expect(l_has_file).to_equal('T');
            ut.expect(l_blob_file is not null).to_be_true;
            ut.expect(l_blob_file.filename).to_equal('fcst.txt');
            ut.expect(l_blob_file.media_type).to_equal('text/plain');
            ut.expect(l_blob_file.quality_code).to_equal(0);
            ut.expect(blob_to_clob(l_blob_file.the_blob)).to_equal(l_file_contents);
         else
            ut.expect(l_has_file).to_equal('F');
            ut.expect(l_blob_file is null).to_be_true;
         end if;
         ----------------
         -- store file --
         ----------------
         begin
            cwms_fcst.store_fcst_file(
               p_fcst_spec_id       => c_fcst_spec_id,
               p_fcst_designator    => c_fcst_designator,
               p_forecast_date_time => c_fcst_date,
               p_issue_date_time    => c_issue_date,
               p_time_zone          => c_time_zone_id,
               p_fcst_file          => cwms_t_blob_file(
                                          filename     => 'fcst.txt',
                                          media_type   => 'text/plain',
                                          quality_code => 0,
                                          the_blob     => clob_to_blob(l_file_contents)),
               p_fail_if_exists     => 'T' ,
               p_office_id          => c_office_id);
            if has_file = 1 then
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               ut.expect(dbms_utility.format_error_stack).to_be_like('%Forecast instance%already has a forecast file%');
         end;
         -------------------
         -- retrieve file --
         -------------------
         dbms_output.put_line('    Verifying operation of Cwms_Fcst.Retrieve_Fcst_File');
         l_blob_file := null;
         cwms_fcst.retrieve_fcst_file(
            p_fcst_file	         => l_blob_file,
            p_fcst_spec_id	      => c_fcst_spec_id,
            p_fcst_designator	   => c_fcst_designator,
            p_forecast_date_time	=> l_fcst_date_utc,
            p_issue_date_time	   => l_issue_date_utc,
            p_time_zone	         => 'UTC',
            p_office_id	         => c_office_id);
         ut.expect(l_blob_file is not null).to_be_true;
         ut.expect(l_blob_file.filename).to_equal('fcst.txt');
         ut.expect(l_blob_file.media_type).to_equal('text/plain');
         ut.expect(l_blob_file.quality_code).to_equal(0);
         ut.expect(blob_to_clob(l_blob_file.the_blob)).to_equal(l_file_contents);
         -----------------
         -- delete inst --
         -----------------
         dbms_output.put_line('    Verifying operation of Cwms_Fcst.Delete_Fcst');
         cwms_fcst.delete_fcst(
            p_fcst_spec_id	      => c_fcst_spec_id,
            p_fcst_designator	   => c_fcst_designator,
            p_forecast_date_time	=> l_fcst_date_utc,
            p_issue_date_time	   => l_issue_date_utc,
            p_office_id	         => c_office_id);
         commit;
         select count(*)
           into l_count
           from cwms_v_fcst_inst
          where office_id = c_office_id
            and fcst_spec_id = c_fcst_spec_id
            and fcst_designator = c_fcst_designator
            and fcst_date_time_utc = l_fcst_date_utc
            and issue_date_time_utc = l_issue_date_utc;
         ut.expect(l_count).to_equal(0);
         select count(*)
           into l_count
           from cwms_v_fcst_info
          where office_id = c_office_id
            and fcst_spec_id = c_fcst_spec_id
            and fcst_designator = c_fcst_designator
            and fcst_date_time_utc = l_fcst_date_utc
            and issue_date_time_utc = l_issue_date_utc;
         ut.expect(l_count).to_equal(0);
      end loop;
   end loop;
end test_fcst_inst_ops;

end test_cwms_fcst;
/
show errors

grant execute on test_cwms_fcst to cwms_user;

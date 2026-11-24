CREATE OR REPLACE package &cwms_schema..test_cwms_text as

--%suite(Test CWMS_TEXT package code)
--%beforeall (setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test saving null text timeseries value)
procedure test_store_null_text_ts;

--%test(AT_BLOB has nullable CREATED_AT, UPDATED_AT and CREATED_BY audit columns)
procedure test_at_blob_audit_columns_exist;

--%test(store_binary insert populates CREATED_AT, UPDATED_AT (UTC) and CREATED_BY)
procedure test_store_binary_insert_sets_audit;

--%test(store_binary insert without p_created_by leaves CREATED_BY null but sets timestamps)
procedure test_store_binary_insert_no_created_by;

--%test(store_binary update preserves CREATED_AT and CREATED_BY and refreshes UPDATED_AT)
procedure test_store_binary_update_preserves_created;

--%test(store_binary update backfills CREATED_AT and CREATED_BY on pre-existing rows that lack them)
procedure test_store_binary_update_backfills_legacy_row;

--%test(store_binary update with p_ignore_nulls = F still maintains audit columns)
procedure test_store_binary_update_no_ignore_nulls;

--%test(store_binary update does not modify other binaries)
procedure test_store_binary_update_only_target_row;

--%test(store_binary with p_fail_if_exists = T raises ITEM_ALREADY_EXISTS)
--%throws(-20020)
procedure test_store_binary_fail_if_exists;

--%test(AT_BLOB still enforces one binary per office and case-insensitive id)
--%throws(-1)
procedure test_at_blob_unique_office_id;

--%test(store_ts_binary with a start time still inserts into AT_BLOB)
procedure test_store_ts_binary_start_time;

--%test(store_ts_binary with a times table still inserts into AT_BLOB)
procedure test_store_ts_binary_times;

test_base_location_id VARCHAR2(32) := 'TestLoc1';
c_start_time    constant date         := date '2020-01-01';
c_blob_id_prefix constant varchar2(32) := '/TEST/AT_BLOB_AUDIT/';

procedure setup;
procedure teardown;
end test_cwms_text;
/
show errors;
/* Formatted on 4/28/2022 2:38:41 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_text
AS
   --------------------------------------------------------------------------------
    -- procedure delete_all
    --------------------------------------------------------------------------------
    PROCEDURE delete_all
    IS
        exc_location_id_not_found   EXCEPTION;
        PRAGMA EXCEPTION_INIT (exc_location_id_not_found, -20025);
    BEGIN
        FOR rec
            IN (SELECT COLUMN_VALUE     AS loc_name
                  FROM TABLE (str_tab_t (test_base_location_id)))
        LOOP
            BEGIN
                cwms_loc.delete_location (
                    p_location_id     => rec.loc_name,
                    p_delete_action   => cwms_util.delete_all,
                    p_db_office_id    => '&&office_id');
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;
        END LOOP;
        delete from at_blob
         where office_code = cwms_util.get_office_code('&&office_id')
           and id like c_blob_id_prefix || '%';
        commit;
    END delete_all;
    PROCEDURE setup
    IS
    BEGIN
        delete_all;
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'F',
                                 p_db_office_id   => '&&office_id');
        COMMIT;
    END;
    PROCEDURE teardown
    IS
    BEGIN
        delete_all;
    END teardown;
    procedure test_store_null_text_ts
    IS
        l_cwms_ts_id      VARCHAR2 (200);
        l_crsr                sys_refcursor;
        l_times            date_table_type := date_table_type();
        l_text                varchar2(32767);
        l_version_date      date;
        l_data_entry_date     date;
        l_clob                clob;
        l_number              number;
        l_count       integer;
        l_end_time      constant date := c_start_time + 1;
        l_start_time    constant date := c_start_time - 1;
        l_date_time       date;

    BEGIN
        l_cwms_ts_id := test_base_location_id || '.Text.Inst.~1Day.0.raw';
        l_times.extend;
        l_times(1) := c_start_time;
        cwms_text.store_ts_text (
            p_tsid => l_cwms_ts_id,
            p_text => null,  
            p_times => l_times,
            p_office_id => '&&office_id'
        );
        l_crsr := cwms_text.retrieve_ts_std_text_f (
            p_tsid             => l_cwms_ts_id,
            p_std_text_id_mask => '*',
            p_start_time       => l_start_time,
            p_end_time         => l_end_time,
            p_time_zone        => 'UTC',
            p_office_id        => '&&office_id');
            l_count := 0;
        loop
            fetch l_crsr
            into l_date_time,
                    l_version_date,
                    l_data_entry_date,
                    l_text,
                    l_number,
                    l_clob;
            exit when l_crsr%notfound;
            l_count := l_count + 1;
        end loop;
        close l_crsr;
        ut.expect(l_text).to_be_null();
        cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, '&&office_id');
    END test_store_null_text_ts;

    --------------------------------------------------------------------------------
    -- AT_BLOB audit column helpers
    --------------------------------------------------------------------------------
    function utc_now return date
    is
    begin
        return cast(sys_extract_utc(systimestamp) as date);
    end utc_now;

    function get_blob_rec(p_id in varchar2) return at_blob%rowtype
    is
        l_rec at_blob%rowtype;
    begin
        select *
          into l_rec
          from at_blob
         where office_code = cwms_util.get_office_code('&&office_id')
           and id = upper(p_id);
        return l_rec;
    end get_blob_rec;

    procedure store_test_binary(
        p_id             in varchar2,
        p_text           in varchar2,
        p_created_by     in varchar2 default null,
        p_fail_if_exists in varchar2 default 'F',
        p_ignore_nulls   in varchar2 default 'T',
        p_description    in varchar2 default null)
    is
        l_code number;
    begin
        cwms_text.store_binary(
            p_binary_code       => l_code,
            p_binary            => utl_i18n.string_to_raw(p_text, 'AL32UTF8'),
            p_id                => p_id,
            p_media_type_or_ext => '.bin',
            p_description       => p_description,
            p_fail_if_exists    => p_fail_if_exists,
            p_ignore_nulls      => p_ignore_nulls,
            p_office_id         => '&&office_id',
            p_created_by        => p_created_by);
    end store_test_binary;

    function blob_text(p_blob in blob) return varchar2
    is
    begin
        return utl_i18n.raw_to_char(dbms_lob.substr(p_blob, 32767, 1), 'AL32UTF8');
    end blob_text;

    --------------------------------------------------------------------------------
    -- procedure test_at_blob_audit_columns_exist
    --------------------------------------------------------------------------------
    procedure test_at_blob_audit_columns_exist
    is
        l_data_type   user_tab_columns.data_type%type;
        l_data_length user_tab_columns.data_length%type;
        l_nullable    user_tab_columns.nullable%type;
    begin
        for rec in (select column_value as col from table(str_tab_t('CREATED_AT', 'UPDATED_AT'))) loop
            select data_type, nullable
              into l_data_type, l_nullable
              from user_tab_columns
             where table_name = 'AT_BLOB'
               and column_name = rec.col;
            ut.expect(l_data_type, rec.col || ' data type').to_equal('DATE');
            ut.expect(l_nullable, rec.col || ' nullable').to_equal('Y');
        end loop;

        select data_type, data_length, nullable
          into l_data_type, l_data_length, l_nullable
          from user_tab_columns
         where table_name = 'AT_BLOB'
           and column_name = 'CREATED_BY';
        ut.expect(l_data_type, 'CREATED_BY data type').to_equal('VARCHAR2');
        ut.expect(l_data_length, 'CREATED_BY length').to_equal(256);
        ut.expect(l_nullable, 'CREATED_BY nullable').to_equal('Y');
    end test_at_blob_audit_columns_exist;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_insert_sets_audit
    --------------------------------------------------------------------------------
    procedure test_store_binary_insert_sets_audit
    is
        l_id     constant varchar2(256) := c_blob_id_prefix || 'insert_sets_audit';
        l_before date;
        l_after  date;
        l_rec    at_blob%rowtype;
    begin
        l_before := utc_now;
        store_test_binary(l_id, 'insert test', p_created_by => 'test_creator', p_fail_if_exists => 'T');
        l_after := utc_now;

        l_rec := get_blob_rec(l_id);
        ut.expect(l_rec.created_by).to_equal('test_creator');
        ut.expect(l_rec.created_at).to_be_between(l_before, l_after);
        ut.expect(l_rec.updated_at).to_be_between(l_before, l_after);
        ut.expect(l_rec.updated_at, 'updated_at = created_at on insert').to_equal(l_rec.created_at);
        ut.expect(blob_text(l_rec.value)).to_equal('insert test');
        rollback;
    end test_store_binary_insert_sets_audit;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_insert_no_created_by
    --------------------------------------------------------------------------------
    procedure test_store_binary_insert_no_created_by
    is
        l_id     constant varchar2(256) := c_blob_id_prefix || 'insert_no_created_by';
        l_before date;
        l_after  date;
        l_rec    at_blob%rowtype;
    begin
        l_before := utc_now;
        store_test_binary(l_id, 'no creator');
        l_after := utc_now;

        l_rec := get_blob_rec(l_id);
        ut.expect(l_rec.created_by).to_be_null();
        ut.expect(l_rec.created_at).to_be_between(l_before, l_after);
        ut.expect(l_rec.updated_at).to_be_between(l_before, l_after);
        rollback;
    end test_store_binary_insert_no_created_by;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_update_preserves_created
    --------------------------------------------------------------------------------
    procedure test_store_binary_update_preserves_created
    is
        l_id          constant varchar2(256) := c_blob_id_prefix || 'update_preserves';
        l_old_created constant date := date '2020-01-01';
        l_old_updated constant date := date '2020-06-01';
        l_before      date;
        l_after       date;
        l_rec         at_blob%rowtype;
    begin
        store_test_binary(l_id, 'original', p_created_by => 'original_user', p_description => 'orig desc');
        -- backdate the audit columns so the update is distinguishable without sleeping
        update at_blob
           set created_at = l_old_created,
               updated_at = l_old_updated
         where office_code = cwms_util.get_office_code('&&office_id')
           and id = upper(l_id);

        l_before := utc_now;
        store_test_binary(l_id, 'updated', p_created_by => 'other_user');
        l_after := utc_now;

        l_rec := get_blob_rec(l_id);
        ut.expect(blob_text(l_rec.value), 'value updated').to_equal('updated');
        ut.expect(l_rec.description, 'description kept with ignore_nulls').to_equal('orig desc');
        ut.expect(l_rec.created_by, 'created_by preserved').to_equal('original_user');
        ut.expect(l_rec.created_at, 'created_at preserved').to_equal(l_old_created);
        ut.expect(l_rec.updated_at, 'updated_at refreshed').to_be_between(l_before, l_after);
        rollback;
    end test_store_binary_update_preserves_created;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_update_backfills_legacy_row
    --------------------------------------------------------------------------------
    procedure test_store_binary_update_backfills_legacy_row
    is
        l_id     constant varchar2(256) := c_blob_id_prefix || 'legacy_row';
        l_before date;
        l_after  date;
        l_rec    at_blob%rowtype;
    begin
        -- simulate a row that existed before the audit columns were added
        store_test_binary(l_id, 'legacy');
        update at_blob
           set created_at = null,
               updated_at = null,
               created_by = null
         where office_code = cwms_util.get_office_code('&&office_id')
           and id = upper(l_id);

        l_rec := get_blob_rec(l_id);
        ut.expect(l_rec.created_at, 'precondition').to_be_null();
        ut.expect(l_rec.updated_at, 'precondition').to_be_null();
        ut.expect(l_rec.created_by, 'precondition').to_be_null();

        l_before := utc_now;
        store_test_binary(l_id, 'legacy updated', p_created_by => 'backfill_user');
        l_after := utc_now;

        l_rec := get_blob_rec(l_id);
        ut.expect(l_rec.created_by, 'created_by backfilled').to_equal('backfill_user');
        ut.expect(l_rec.created_at, 'created_at backfilled').to_be_between(l_before, l_after);
        ut.expect(l_rec.updated_at, 'updated_at set').to_be_between(l_before, l_after);
        ut.expect(blob_text(l_rec.value)).to_equal('legacy updated');
        rollback;
    end test_store_binary_update_backfills_legacy_row;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_update_no_ignore_nulls
    --------------------------------------------------------------------------------
    procedure test_store_binary_update_no_ignore_nulls
    is
        l_id          constant varchar2(256) := c_blob_id_prefix || 'no_ignore_nulls';
        l_old_created constant date := date '2020-01-01';
        l_before      date;
        l_after       date;
        l_rec         at_blob%rowtype;
    begin
        store_test_binary(l_id, 'original', p_created_by => 'original_user', p_description => 'orig desc');
        update at_blob
           set created_at = l_old_created,
               updated_at = l_old_created
         where office_code = cwms_util.get_office_code('&&office_id')
           and id = upper(l_id);

        l_before := utc_now;
        store_test_binary(l_id, 'replaced', p_ignore_nulls => 'F');
        l_after := utc_now;

        l_rec := get_blob_rec(l_id);
        ut.expect(l_rec.description, 'description nulled').to_be_null();
        ut.expect(l_rec.created_by, 'created_by preserved').to_equal('original_user');
        ut.expect(l_rec.created_at, 'created_at preserved').to_equal(l_old_created);
        ut.expect(l_rec.updated_at, 'updated_at refreshed').to_be_between(l_before, l_after);
        rollback;
    end test_store_binary_update_no_ignore_nulls;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_update_only_target_row
    --------------------------------------------------------------------------------
    procedure test_store_binary_update_only_target_row
    is
        l_id_1        constant varchar2(256) := c_blob_id_prefix || 'target_1';
        l_id_2        constant varchar2(256) := c_blob_id_prefix || 'target_2';
        l_old_updated constant date := date '2020-01-01';
        l_rec         at_blob%rowtype;
    begin
        store_test_binary(l_id_1, 'one', p_created_by => 'user_1');
        store_test_binary(l_id_2, 'two', p_created_by => 'user_2');
        update at_blob
           set updated_at = l_old_updated
         where office_code = cwms_util.get_office_code('&&office_id')
           and id = upper(l_id_2);

        store_test_binary(l_id_1, 'one updated');

        l_rec := get_blob_rec(l_id_2);
        ut.expect(blob_text(l_rec.value), 'other value untouched').to_equal('two');
        ut.expect(l_rec.created_by, 'other created_by untouched').to_equal('user_2');
        ut.expect(l_rec.updated_at, 'other updated_at untouched').to_equal(l_old_updated);
        rollback;
    end test_store_binary_update_only_target_row;

    --------------------------------------------------------------------------------
    -- procedure test_store_binary_fail_if_exists
    --------------------------------------------------------------------------------
    procedure test_store_binary_fail_if_exists
    is
        l_id constant varchar2(256) := c_blob_id_prefix || 'fail_if_exists';
    begin
        store_test_binary(l_id, 'first', p_fail_if_exists => 'T');
        begin
            store_test_binary(l_id, 'second', p_fail_if_exists => 'T');
        exception
            when others then
                rollback;
                raise;
        end;
        rollback;
    end test_store_binary_fail_if_exists;

    --------------------------------------------------------------------------------
    -- procedure test_at_blob_unique_office_id
    --------------------------------------------------------------------------------
    procedure test_at_blob_unique_office_id
    is
        l_id  constant varchar2(256) := c_blob_id_prefix || 'unique_id';
        l_rec at_blob%rowtype;
    begin
        store_test_binary(l_id, 'first');
        l_rec := get_blob_rec(l_id);
        begin
            -- same office and id (different case), different created_at: must still be rejected
            insert into at_blob (blob_code, office_code, id, description, media_type_code, value, created_at, updated_at)
            values (cwms_seq.nextval,
                    cwms_util.get_office_code('&&office_id'),
                    lower(l_id),
                    null,
                    l_rec.media_type_code,
                    utl_i18n.string_to_raw('duplicate', 'AL32UTF8'),
                    date '2000-01-01',
                    date '2000-01-01');
        exception
            when others then
                rollback;
                raise;
        end;
        rollback;
    end test_at_blob_unique_office_id;

    --------------------------------------------------------------------------------
    -- procedure test_store_ts_binary_start_time
    --------------------------------------------------------------------------------
    procedure test_store_ts_binary_start_time
    is
        l_tsid         constant varchar2(200) := test_base_location_id || '.Binary.Inst.~1Day.0.BlobAuditStart';
        l_count_before integer;
        l_count_after  integer;
    begin
        select count(*) into l_count_before from at_blob where id like '/TIME SERIES BINARY/%';
        cwms_text.store_ts_binary(
            p_tsid        => l_tsid,
            p_binary      => utl_i18n.string_to_raw('ts binary start', 'AL32UTF8'),
            p_binary_type => '.bin',
            p_start_time  => c_start_time,
            p_time_zone   => 'UTC',
            p_office_id   => '&&office_id');
        select count(*) into l_count_after from at_blob where id like '/TIME SERIES BINARY/%';
        ut.expect(l_count_after - l_count_before).to_equal(1);
        rollback;
    end test_store_ts_binary_start_time;

    --------------------------------------------------------------------------------
    -- procedure test_store_ts_binary_times
    --------------------------------------------------------------------------------
    procedure test_store_ts_binary_times
    is
        l_tsid         constant varchar2(200) := test_base_location_id || '.Binary.Inst.~1Day.0.BlobAuditTimes';
        l_times        date_table_type := date_table_type(c_start_time);
        l_count_before integer;
        l_count_after  integer;
    begin
        select count(*) into l_count_before from at_blob where upper(id) like '/TIME SERIES BINARY/%';
        cwms_text.store_ts_binary(
            p_tsid        => l_tsid,
            p_binary      => utl_i18n.string_to_raw('ts binary times', 'AL32UTF8'),
            p_binary_type => '.bin',
            p_times       => l_times,
            p_time_zone   => 'UTC',
            p_office_id   => '&&office_id');
        select count(*) into l_count_after from at_blob where upper(id) like '/TIME SERIES BINARY/%';
        ut.expect(l_count_after - l_count_before).to_equal(1);
        rollback;
    end test_store_ts_binary_times;

END test_cwms_text;
/
show errors;
grant execute on test_cwms_text to cwms_user;

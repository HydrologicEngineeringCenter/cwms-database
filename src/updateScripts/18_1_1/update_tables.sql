declare
   l_val pls_integer;
   l_sql varchar2(4000) := '
      create or replace trigger :table_name_ddf
         before insert or update on :table_name
         for each row
      begin
         if inserting or updating then
            :new.dest_flag := cwms_data_dissem.get_dest(:new.ts_code);
         end if;
      exception
         -- silently fail
         when others then null;
       end;';
begin
   -----------------------------------------------------------
   -- lengthen AT_SEC_CWMS_USERS.PHONE column from 16 to 24 --
   -----------------------------------------------------------
   select data_length
     into l_val
     from user_tab_cols
    where table_name = 'AT_SEC_CWMS_USERS'
      and column_name = 'PHONE';

   if l_val < 24 then
      execute immediate 'alter table at_sec_cwms_users modify (phone varchar2(24))';
   end if;
   -----------------------------------------------------------------------
   -- add DEST_FLAG column and associated trigger to time series tables --
   -----------------------------------------------------------------------
   for rec in (select table_name
                 from at_ts_table_properties
               union
               select 'AT_TSV' as table_name
                 from dual
              )
   loop
      select count(*)
        into l_val
        from user_tab_cols
       where table_name = rec.table_name
         and column_name = 'DEST_FLAG';

      if l_val = 0 then
         execute immediate 'alter table '||rec.table_name||' add (dest_flag number(1))';
      end if;
      execute immediate replace(l_sql, ':table_name', rec.table_name);
   end loop;
   ----------------------------------------
   -- add AT_QUEUE_SUBSCRIBER_NAME table --
   ----------------------------------------
   select count(*)
     into l_val
     from user_tables
    where table_name = 'AT_QUEUE_SUBSCRIBER_NAME';

   if l_val = 0 then
      execute immediate '
         create table at_queue_subscriber_name (
            subscriber_name  varchar2(30) primary key,
            queue_name       varchar2(30) not null,
            create_time      timestamp    not null,
            update_time      timestamp,
            db_user          varchar2(30) not null,
            os_user          varchar2(30) not null,
            host_name        varchar2(64) not null,
            application_name varchar2(48) not null,
            os_process_id    integer      not null
         )
         tablespace cwms_20at_data';

         execute immediate 'comment on table  at_queue_subscriber_name is ''Holds registered subscribers for queue messages''';
         execute immediate 'comment on column at_queue_subscriber_name.subscriber_name   is ''The subscriber name''';
         execute immediate 'comment on column at_queue_subscriber_name.queue_name        is ''The queue the subscription is for''';
         execute immediate 'comment on column at_queue_subscriber_name.create_time       is ''The time the subscriber was created''';
         execute immediate 'comment on column at_queue_subscriber_name.update_time       is ''The last time the subscriber was updated with another pid''';
         execute immediate 'comment on column at_queue_subscriber_name.db_user           is ''The session user that created the subscriber''';
         execute immediate 'comment on column at_queue_subscriber_name.os_user           is ''The client OS user that created the subscriber''';
         execute immediate 'comment on column at_queue_subscriber_name.host_name         is ''The name of the client system that created the subscriber''';
         execute immediate 'comment on column at_queue_subscriber_name.application_name  is ''The application name assosicated with the subscriber''';
         execute immediate 'comment on column at_queue_subscriber_name.os_process_id     is ''The process identifier (pid) associated with the subscriber''';

         execute immediate 'create index at_queue_subscriber_name_idx1 on at_queue_subscriber_name (queue_name, nvl(update_time, create_time))';
   end if;
   ------------------------------------------
   -- add AT_PHYSICAL_LOCATION_T02 trigger --
   ------------------------------------------
   select count(*)
     into l_val
     from user_triggers
    where trigger_name = 'AT_PHYSICAL_LOCATION_T02';

   if l_val = 0 then
      execute immediate '
         create or replace trigger at_physical_location_t02
             before insert or update
             on at_physical_location
             referencing new as new old as old
             for each row
         declare
             l_lat_lon_changed boolean;
             l_update_non_null boolean;
             l_county_code	   integer;
         begin
             if :new.latitude is not null and :new.longitude is not null then
                -------------------------------------------------------------
                -- won''t apply to sub-locations that inherit their lat/lon --
                -------------------------------------------------------------
                l_lat_lon_changed :=
                   :old.latitude is null
                   or :old.longitude is null
                   or :new.latitude != :old.latitude
                   or :new.longitude != :old.longitude;
                if l_lat_lon_changed then
                   l_update_non_null := instr(
                 ''TRUE'',
                 upper(cwms_properties.get_property(
                    ''CWMSDB'',
                    ''location.update_non_null_items_on_latlon_change'',
                    ''false''))) = 1;
                end if;
                if :new.county_code is null or mod(:new.county_code, 1000) = 0 or (l_lat_lon_changed and l_update_non_null) then
                   -------------------------------------
                   -- get the county from the lat/lon --
                   -------------------------------------
                   l_county_code := cwms_loc.get_county_code(:new.latitude, :new.longitude);
                   if l_county_code is not null then
                 :new.county_code := l_county_code;
                 if :new.nation_code is null then
                    :new.nation_code := ''US'';
                 end if;
                   end if;
                end if;
                if :new.office_code is null or (l_lat_lon_changed and l_update_non_null) then
                   ----------------------------------------------
                   -- get the bounding office from the lat/lon --
                   ----------------------------------------------
                   :new.office_code := cwms_loc.get_bounding_ofc_code(:new.latitude, :new.longitude);
                end if;
                if :new.nearest_city is null or (l_lat_lon_changed and l_update_non_null) then
                   -------------------------------------------
                   -- get the nearest city from the lat/lon --
                   -------------------------------------------
                   :new.nearest_city := cwms_loc.get_nearest_city(:new.latitude, :new.longitude)(1);
                end if;
             end if;
         exception
             when others then cwms_err.raise(''ERROR'', dbms_utility.format_error_backtrace);
         end at_physical_location_t02;';
   end if;
   ------------------------------------------------------
   -- make sure AT_TRANSITIONAL_RATING_U1 index exists --
   ------------------------------------------------------
   select count(*)
     into l_val
     from all_indexes
    where owner = 'CWMS_20'
      and index_name = 'AT_TRANSITIONAL_RATING_U1';
      
   if l_val = 0 then
      execute immediate 'create unique index at_transitional_rating_u1 on at_transitional_rating(rating_spec_code, effective_date)';
   end if;
   -------------------------------------------------
   -- make sure AT_VIRTUAL_RATING_U1 index exists --
   -------------------------------------------------
   select count(*)
     into l_val
     from all_indexes
    where owner = 'CWMS_20'
      and index_name = 'AT_VIRTUAL_RATING_U1';
      
   if l_val = 0 then
      execute immediate 'create unique index at_virtual_rating_u1 on at_virtual_rating(rating_spec_code, effective_date)';
   end if;
   ----------------------------------------------
   -- new AT_LOG_MESSAGE_PROPERTIES_IDX1 index --
   ----------------------------------------------
   execute immediate '
      create index at_log_message_properties_idx1
                on at_log_message_properties (
                  prop_name,
                  nvl(prop_text, prop_value),
                  msg_id
                ) tablespace cwms_20at_data';
   ----------------------------------------
   -- patch up AT_DATA_STREAM_PROPERTIES --
   ----------------------------------------
   select count(*)
     into l_val
     from all_constraints
    where owner = 'CWMS_20'
      and table_name = 'AT_DATA_STREAM_PROPERTIES'
      and constraint_name = 'AT_DATA_STREAM_PROPERTIES_R01';
      
   if l_val = 0 then
      execute immediate 'alter table at_data_stream_properties add constraint at_data_stream_properties_r01 foreign key (db_office_code) references cwms_office (office_code)';
   end if;
   --------------------------
   -- patch up AT_TSV_XXXX --
   --------------------------
   declare
      type table_name_t is table of varchar2(30);
      l_table_names table_name_t := table_name_t('AT_TSV_2016', 'AT_TSV_2019', 'AT_TSV_2020');
   begin
      for i in 1..l_table_names.count loop
         select count(*)
           into l_val
           from all_constraints
          where owner = 'CWMS_20'
            and table_name = l_table_names(i)
            and constraint_name = l_table_names(i)||'_FK1';
            
         if l_val = 0 then
            execute immediate 
               'alter table '
               ||l_table_names(i)
               ||' add constraint '
               ||l_table_names(i)
               ||'_fk1 foreign key (ts_code) references at_cwms_ts_spec (ts_code)';
         end if;
      end loop;
   end;
   --------------------------
   -- patch up AT_TSV_2018 --
   --------------------------
   select count(line)
     into l_val
     from all_source
    where owner = 'CWMS_20'
      and type = 'TRIGGER'
      and name = 'AT_TSV_2018_AIUDR';
      
   if l_val > 23 then
      execute immediate 'create or replace TRIGGER AT_TSV_2018_AIUDR
        AFTER insert or update or delete ON AT_TSV_2018 FOR EACH ROW
        DECLARE
                l_dml number;
        BEGIN
        -- count inserts, updates and deletes using the cwms_tsv package

                l_dml := 0;

                if INSERTING then
                        l_dml := 1;
                elsif UPDATING then
                        l_dml := 2;
                elsif DELETING then
                        l_dml := 3;
                end if;

        cwms_tsv.count(l_dml, sys_extract_utc(systimestamp));

        EXCEPTION
        -- silently fail
        WHEN OTHERS THEN NULL;
    END;';
   end if;
   ------------------------------
   -- patch up AT_CWMS_TS_SPEC --
   ------------------------------
   execute immediate 'drop index at_cwms_ts_spec_ui';
   execute immediate 'create unique index at_cwms_ts_spec_ui on at_cwms_ts_spec (location_code, parameter_type_code, parameter_code, interval_code, duration_code, upper(version), delete_date)';
   --------------------------------------
   -- patch up AT_LOC_GROUP_ASSIGNMENT -- 
   --------------------------------------
   select data_precision
     into l_val
     from all_tab_columns
    where owner = 'CWMS_20'
      and table_name = 'AT_LOC_GROUP_ASSIGNMENT'
      and column_name = 'OFFICE_CODE';
      
   if l_val is null then
      execute immediate 'drop index at_loc_group_assignment_idx1';
      execute immediate 'select * from at_loc_group_assignment';
      execute immediate 'create table at_loc_group_assignment$ as select * from at_loc_group_assignment';
      execute immediate 'truncate table at_loc_group_assignment';
      execute immediate 'alter table at_loc_group_assignment modify office_code number(10)';
      execute immediate 'insert into at_loc_group_assignment select * from at_loc_group_assignment$';
      execute immediate 'drop table at_loc_group_assignment$';
      execute immediate 'create index at_loc_group_assignment_idx1 on at_loc_group_assignment (office_code, upper(loc_alias_id))';
   end if;
   -------------------------------------
   -- patch up AT_TS_GROUP_ASSIGNMENT -- 
   -------------------------------------
   select data_precision
     into l_val
     from all_tab_columns
    where owner = 'CWMS_20'
      and table_name = 'AT_TS_GROUP_ASSIGNMENT'
      and column_name = 'OFFICE_CODE';
      
   if l_val is null then
      execute immediate 'drop index at_ts_group_assignment_idx1';
      execute immediate 'select * from at_ts_group_assignment';
      execute immediate 'create table at_ts_group_assignment$ as select * from at_ts_group_assignment';
      execute immediate 'truncate table at_ts_group_assignment';
      execute immediate 'alter table at_ts_group_assignment modify office_code number(10)';
      execute immediate 'insert into at_ts_group_assignment select * from at_ts_group_assignment$';
      execute immediate 'drop table at_ts_group_assignment$';
      execute immediate 'create index at_ts_group_assignment_idx1 on at_ts_group_assignment (office_code, upper(ts_alias_id))';
   end if;
   -----------------------
   -- patch up CWMS_NID --
   -----------------------
   select count(*)
     into l_val
     from all_cons_columns
    where owner = 'CWMS_20'
      and table_name = 'CWMS_NID'
      and constraint_name = 'CWMS_NID_U1'
      and position = 1
      and column_name = 'RECORDID';
      
   if l_val = 1 then
      execute immediate 'alter table cwms_nid drop constraint cwms_nid_u1';
      execute immediate 'drop index cwms_nid_u1';
      execute immediate 'alter table cwms_nid add constraint cwms_nid_u1 unique (nidid)';
   end if;
   -----------------------------
   -- patch up AT_RATING_SPEC --
   -----------------------------
   select count(*)
     into l_val
     from all_constraints
    where owner = 'CWMS_20'
      and table_name = 'AT_RATING_SPEC'
      and constraint_name = 'AT_RATING_SPEC_FK3';
      
   if l_val = 0 then
      execute immediate 'alter table at_rating_spec add constraint at_rating_spec_fk3 foreign key (source_agency_code) references at_entity (entity_code)';
   end if;
   ---------------------------------
   -- patch up AT_STREAM_LOCATION --
   ---------------------------------
   select count(*)
     into l_val
     from all_constraints
    where owner = 'CWMS_20'
      and table_name = 'AT_STREAM_LOCATION'
      and constraint_name = 'AT_STREAM_LOCATION_PK'
      and index_name = 'AT_STREAM_LOC_CODE_SLC_IDX';
      
   if l_val = 1 then
      declare
         type cons_rec_t is record (table_name varchar2(30), column_name varchar2(30), constraint_name varchar2(30));
         type cons_tab_t is table of cons_rec_t;
         l_dependent_constraints cons_tab_t := cons_tab_t();
      begin
         for rec in (select acc.constraint_name,
                            acc.table_name,
                            acc.column_name,
                            acc.position
                       from all_constraints ac,
                            all_cons_columns acc
                      where ac.r_constraint_name = 'AT_STREAM_LOCATION_PK'
                        and acc.constraint_name = ac.constraint_name
                      order by 1, 4
                    )
         loop
            if rec.position > 1 then
               raise_application_error(-20999, 'Compound foreign key encountered');
            end if;
            l_dependent_constraints.extend();
            l_dependent_constraints(l_dependent_constraints.count).constraint_name := rec.constraint_name;
            l_dependent_constraints(l_dependent_constraints.count).table_name := rec.table_name;
            l_dependent_constraints(l_dependent_constraints.count).column_name := rec.column_name;
            execute immediate 'alter table '||rec.table_name||' drop constraint '||rec.constraint_name;
         end loop;
         execute immediate 'alter table at_stream_location drop constraint at_stream_location_pk';
         execute immediate 'drop index at_stream_loc_code_slc_idx';
         execute immediate 'alter table at_stream_location add constraint at_stream_location_pk primary key (location_code) using index';
         for i in 1..l_dependent_constraints.count loop
            execute immediate 
               'alter table '
               ||l_dependent_constraints(i).table_name
               ||' add constraint '
               ||l_dependent_constraints(i).constraint_name
               ||' foreign key ('
               ||l_dependent_constraints(i).column_name
               ||') references at_stream_location (location_code)';
         end loop;
      end;
   end if;
end;   
/


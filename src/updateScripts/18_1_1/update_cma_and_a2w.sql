declare
   l_column_count pls_integer;
   
   procedure might_fail(p_sql in varchar2)
   is
   begin
      execute immediate p_sql;
   exception
      when others then null;
   end;
begin
   -------------------------
   -- add missing columns --
   -------------------------
   select max(column_id)
     into l_column_count
     from user_tab_columns 
    where table_name = 'AT_A2W_TS_CODES_BY_LOC';
    
   case l_column_count
   when 26 then execute immediate 'alter table at_a2w_ts_codes_by_loc add (
      rating_code_elev_area   number,
      rating_code_outlet_flow number,
      ts_code_opening         number,
      opening_source_obj      varchar2(5),
      ts_code_wind_dir        number,
      ts_code_wind_speed      number,
      ts_code_volt            number,
      ts_code_pct_flood       number,
      ts_code_pct_con         number,
      ts_code_irrad           number,
      ts_code_evap            number)';
   when 30 then
      execute immediate 'alter table at_a2w_ts_codes_by_loc add (
         ts_code_wind_dir   number,
         ts_code_wind_speed number,
         ts_code_volt       number,
         ts_code_pct_flood  number,
         ts_code_pct_con    number,
         ts_code_irrad      number,
         ts_code_evap       number)';
   when 37 then null;
   end case;
   ------------------------------------
   -- replace missing default values --
   ------------------------------------
   execute immediate 'alter table at_a2w_ts_codes_by_loc modify display_flag varchar2(1) default ''F'''; 
   execute immediate 'alter table at_a2w_ts_codes_by_loc modify num_ts_codes number default 0'; 
   execute immediate 'alter table at_a2w_ts_codes_by_loc modify lake_summary_tf varchar2(1) default ''F''';
   -------------------------------------
   -- update indexes and constraints --
   -------------------------------------
   might_fail('alter table at_a2w_ts_codes_by_loc drop constraint at_a2w_ts_codes_by_loc_u01');
   might_fail('alter table at_a2w_ts_codes_by_loc drop constraint at_a2w_ts_codes_by_loc_pk');
   might_fail('drop index at_a2w_ts_codes_by_loc_u01');
   might_fail('drop index at_a2w_ts_codes_by_loc_pk');
   might_fail('drop index at_a2w_active_drought_idx'); 
   might_fail('create index at_a2w_active_cond_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_cond asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_do_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_do asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_drought_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_stor_drought asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_elev_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_elev asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_elev_tw_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_elev_tw asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_flood_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_stor_flood asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_inflow_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_inflow asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_outflow_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_outflow asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_ph_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_ph asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_power_gen_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_power_gen asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_precip_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_precip asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_rating_es_idx on at_a2w_ts_codes_by_loc (location_code asc, rating_code_elev_stor asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_rc_elev_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_rule_curve_elev asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_stage_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_stage asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_stage_tw_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_stage_tw asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_sur_release_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_sur_release asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_temp_air_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_temp_air asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_active_temp_water_idx on at_a2w_ts_codes_by_loc (location_code asc, ts_code_temp_water asc, display_flag asc) tablespace cwms_20data'); 
   might_fail('create index at_a2w_loc_code_flag_idx on at_a2w_ts_codes_by_loc (location_code asc, display_flag asc) tablespace cwms_20data');
   execute immediate 'create unique index at_a2w_ts_codes_by_loc_pk on at_a2w_ts_codes_by_loc (location_code)';
   execute immediate 'alter table at_a2w_ts_codes_by_loc add constraint at_a2w_ts_codes_by_loc_pk primary key (location_code) using index at_a2w_ts_codes_by_loc_pk';
end;
/
comment on table  at_a2w_ts_codes_by_loc is 'The AT_A2W_TS_CODES_BY_LOC table stores the WM choice of TS Codes representing a locations elevation, precipitation, stage, inflow, outflow, flood storage, drought storage, and surcharge releases. The TS Codes establish a 1:1 relationship between location and display in various nationwide/public reports. Additional details are in the column comments/';
comment on column at_a2w_ts_codes_by_loc.location_id is          'The Location this record applies to';
comment on column at_a2w_ts_codes_by_loc.db_office_id is         'The office that the record is owned by';
comment on column at_a2w_ts_codes_by_loc.ts_code_elev is         'The TS Code showing elevation (projects)';
comment on column at_a2w_ts_codes_by_loc.ts_code_precip is       'The TS Code showing precipitation at the project';
comment on column at_a2w_ts_codes_by_loc.ts_code_stage is        'The TS Code showing stage (stream gages)';
comment on column at_a2w_ts_codes_by_loc.ts_code_inflow is       'The TS Code showing inflow into the reservoir';
comment on column at_a2w_ts_codes_by_loc.ts_code_outflow is      'The TS Code showing outflow through the project';
comment on column at_a2w_ts_codes_by_loc.date_refreshed is       'The date this record was created/last updated';
comment on column at_a2w_ts_codes_by_loc.ts_code_stor_flood is   'The TS Code showing calculated flood storage';
comment on column at_a2w_ts_codes_by_loc.notes is                'Any notes generated by the initial data load or the WM through CMA';
comment on column at_a2w_ts_codes_by_loc.display_flag is         'Flag recording the WM choice to display this location in a hierarchy';
comment on column at_a2w_ts_codes_by_loc.num_ts_codes is         'Calculated count of TS Codes (+1 ea. for elev,precip,stage, etc.)';
comment on column at_a2w_ts_codes_by_loc.ts_code_stor_drought is 'The TS Code showing calculated drought/conservation storage storage';
comment on column at_a2w_ts_codes_by_loc.lake_summary_tf is      'The flag recording if this location should be in the lake summary report';
comment on column at_a2w_ts_codes_by_loc.ts_code_sur_release is  'The TS Code showing Surchage Releases (flow)';
comment on column at_a2w_ts_codes_by_loc.opening_source_obj is   'Use the Opening obj or TS Code (OBJ or TS)';

 
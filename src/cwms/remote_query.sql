--##############################################################################
-- VARIABLE DEFINITIONS
--##############################################################################
define cwms_schema           = 'cwms_20'                 -- remote schema name (cwms v2 remote only)
define retrieve_ts_minutes   = '70'                      -- number of minutes of data to retrieve in job
define retrieve_job_interval = '60'                      -- job interval in minutes
define office_id             = 'SWT'                     -- office_id for database link name
define cwms_pass             = '********'                -- cwms password for database link (v1.5 or v2 remote)
define remote_db_url         = '155.88.11.61:1521/WM5B'  -- host:port/SID for remote database (v1.5 or v2 remote)

whenever sqlerror continue

drop table remote_offices;
drop table remote_tsid_masks;
drop table remote_tsids;

whenever sqlerror exit sql.sqlcode

--##############################################################################
-- TABLES
--##############################################################################
create table remote_offices
(
   src_office_id varchar2(16),
   dst_office_id varchar2(16),
   dblink        varchar2(31) not null,
   cwms_ver      varchar2(3)  not null
);
alter table remote_offices add constraint remote_offices_pk  primary key (src_office_id, dst_office_id);
alter table remote_offices add constraint remote_offices_ck1 check (upper(src_office_id) = src_office_id);
alter table remote_offices add constraint remote_offices_ck2 check (upper(dst_office_id) = dst_office_id);
alter table remote_offices add constraint remote_offices_ck3 check (cwms_ver = '1.5' or cwms_ver = '2.0');

create table remote_tsid_masks
(
   dblink    varchar2(31),
   mask      varchar2(193)
);
alter table remote_tsid_masks add constraint remote_tsis_masks_pk primary key (dblink, mask) using index;

create table remote_tsids
(
   dblink              varchar2(31),
   ts_code             number(10),
   interval_utc_offset number(10),
   ts_id               varchar2(193) not null
);
alter table remote_tsids add constraint remote_tsids_pk primary key (dblink, ts_code) using index;

--##############################################################################
-- PACKAGE SPECIFICATION
--##############################################################################
create or replace package remote_query
as

--------------------------------------------------------------------------------
-- POPULATE_TSIDS
--
-- Only call this if you have manually edited the REMOTE_OFFICES and/or 
-- REMOTE_TSID_MASKS tables.  Call this before CREATE_LOCATIONS.
--------------------------------------------------------------------------------
procedure populate_tsids(
   p_office_id in varchar2);  -- 'LRH', 'SPK', etc...

--------------------------------------------------------------------------------
-- CREATE_LOCATIONS
--
-- Only call this if you have manually edited the REMOTE_OFFICES and/or 
-- REMOTE_TSID_MASKS tables.  Call this after POPULATE_TSIDS
--------------------------------------------------------------------------------
procedure create_locations(
   p_office_id in varchar2); -- 'LRH', 'SPK', etc...
   
--------------------------------------------------------------------------------
-- SET_OFFICE
--
-- Populates the REMOTE_OFFICES and REMOTE_TSID_MASKS tables and calls
-- POPULATE_TSIDS and CREATE_LOCATIONS.
--------------------------------------------------------------------------------
procedure set_office(
   p_office_id  in varchar2,  -- 'LRH', 'SPK', etc... or SRC/DST (e.g. 'NWD/NWO')
   p_dblink     in varchar2,  -- database link
   p_cwms_ver   in varchar2,  -- must be '1.5' or '2.0'
   p_tsid_masks in varchar2); -- comma-separated list of tsid masks

--------------------------------------------------------------------------------
-- RETRIEVE_TIMESERIES
--
-- Retrieves time series data from the specified office(s) for the specified
-- date range.  The p_office_id_masks parameter can be used to group offices
-- (e.g., 'SW_,SP_' would retrieve data for all Southwestern and South Pacific
-- offices, '%' would retrieve all offices, etc...)
--------------------------------------------------------------------------------
procedure retrieve_timeseries(
   p_offices_processed out integer,
   p_tsids_processed   out integer,
   p_values_retrieved  out integer,
   p_office_id_masks   in  varchar2,
   p_start_time_utc    in date,
   p_end_time_utc      in date default null); -- null = current time
   
--------------------------------------------------------------------------------
-- RETRIEVE_AND_LOG
--
-- Calls RETRIEVE_TIMESERIES and logs start time, end time and items processed
--------------------------------------------------------------------------------
procedure retrieve_and_log(
   p_office_id_masks   in varchar2,
   p_start_time_utc    in date,
   p_end_time_utc      in date default null); -- null = current time
   
--------------------------------------------------------------------------------
-- RETRIEVE_AND_LOG
--
-- Calls RETRIEVE_TIMESERIES and logs start time, end time and items processed
--------------------------------------------------------------------------------
procedure retrieve_and_log(
   p_office_id_masks  in varchar2,
   p_days_to_retrieve in number);   
   
procedure retrieve_job;   
   
end;
/
show errors

--##############################################################################
-- PACKAGE BODY
--##############################################################################
CREATE OR REPLACE package body remote_query
as

--------------------------------------------------------------------------------
-- GET_TS_CODES
--------------------------------------------------------------------------------
function get_ts_codes(
   p_office_id  in varchar2,
   p_tsid_masks in varchar2)
   return clob
is
   type l_rec_t is record(
                   ts_code             integer,
                   interval_utc_offset integer,
                   cwms_id             varchar2(16),
                   subcwms_id          varchar2(32),
                   parameter_id        varchar2(16),
                   subparameter_id     varchar2(32),
                   parameter_type_id   varchar2(16),
                   interval_id         varchar2(16),
                   duration_id         varchar2(16),
                   version             varchar2(48));
   l_src_office_id varchar2(16);
   l_dst_office_id varchar2(16);
   l_dblink        varchar2(31);
   l_cwms_ver      varchar2(3);
   l_clob          clob;
   l_cursor        sys_refcursor;
   l_tsid_masks    str_tab_t;
   l_tsid_parts    str_tab_t;
   l_location      varchar2(64);
   l_parameter     varchar2(64);
   l_param_type    varchar2(64);
   l_interval      varchar2(64);
   l_duration      varchar2(64);
   l_version       varchar2(64);
   l_first         boolean := true;
   l_rec           l_rec_t;
   l_query_str     varchar2(32767);
   procedure append_clob(p_data in varchar2) is
   begin
      dbms_lob.writeappend(l_clob, length(p_data), p_data);
   end;
begin
   l_tsid_masks := cwms_util.split_text(upper(p_office_id), '/', 1);
   l_src_office_id := l_tsid_masks(1);
   l_dst_office_id := l_tsid_masks(l_tsid_masks.count);
   ---------------------------
   -- get the database link --
   ---------------------------
   select dblink,
          cwms_ver
     into l_dblink,
          l_cwms_ver
     from remote_offices
    where src_office_id = l_src_office_id
      and dst_office_id = l_dst_office_id;

   dbms_lob.createtemporary(l_clob, true);
   dbms_lob.open(l_clob, dbms_lob.lob_readwrite);
   l_tsid_masks := cwms_util.split_text(p_tsid_masks, ',');
   for i in 1..l_tsid_masks.count loop
      l_tsid_parts := cwms_util.split_text(upper(l_tsid_masks(i)), '.');
      if l_tsid_parts.count != 6 then
         raise_application_error(
            -20999,
            'TSID mask must contain 6 parts separated by periods: '
            || l_tsid_masks(i),
            false);
      end if;
      l_location   := l_tsid_parts(1);
      l_parameter  := l_tsid_parts(2);
      l_param_type := l_tsid_parts(3);
      l_interval   := l_tsid_parts(4);
      l_duration   := l_tsid_parts(5);
      l_version    := l_tsid_parts(6);
      if l_cwms_ver = '1.5' then
         l_query_str  :=
            --------------------
            -- CWMS 1.5 query --
            --------------------
            'select ts.ts_code,
                    ts.interval_utc_offset,
                    n.cwms_id,
                    ts.subcwms_id,
                    p.parameter_id,
                    ts.subparameter_id,
                    pt.parameter_type_id,
                    i.interval_id,
                    d.duration_id,
                    ts.version
               from cwms.at_cwms_ts_spec@:dblink ts,
                    cwms.at_point_location@:dblink l,
                    cwms.at_cwms_name@:dblink n,
                    cwms.at_office@:dblink o,
                    cwms.rt_parameter@:dblink p,
                    cwms.rt_parameter_type@:dblink pt,
                    cwms.rt_interval@:dblink i,
                    cwms.rt_duration@:dblink d
              where o.office_id = :office_id
                and n.office_code = o.office_code
                and (n.cwms_id_uc like :location
                     or (n.cwms_id_uc || ''-'' || upper(ts.subcwms_id)) like :location)
                and (p.parameter_id_uc like :parameter
                     or (p.parameter_id_uc || ''-'' || upper(ts.subparameter_id)) like :parameter)
                and pt.parameter_type_id_uc like :param_type
                and upper(i.interval_id) like :interval
                and upper(d.duration_id) like :duration
                and ts.version_uc like :version
                and l.location_code = ts.location_code
                and n.cwms_code = l.cwms_code
                and p.parameter_code = ts.parameter_code
                and pt.parameter_type_code = ts.parameter_type_code
                and i.interval_code = ts.interval_code
                and d.duration_code = ts.duration_code';
            l_query_str := replace(l_query_str, ':dblink', l_dblink); -- can't bind
            open l_cursor
             for l_query_str
           using l_src_office_id,
                 l_location,
                 l_location,
                 l_parameter,
                 l_parameter,
                 l_param_type,
                 l_interval,
                 l_duration,
                 l_version;
         else
            --------------------
            -- CWMS 2.0 query --
            --------------------
            l_query_str :=
               'select ts_code,
                       interval_utc_offset,
                       base_location_id cwms_id,
                       sub_location_id subcwms_id,
                       base_parameter_id parameter_id,
                       sub_parameter_id subparameter_id,
                       parameter_type_id,
                       interval_id,
                       duration_id,
                       version_id version
                  from '||'&cwms_schema'||'.mv_cwms_ts_id@:dblink
                 where db_office_id = :office_id
                   and upper(location_id) like :location
                   and upper(parameter_id) like :parameter
                   and upper(parameter_type_id) like :param_type
                   and upper(interval_id) like :interval
                   and upper(duration_id) like :duration
                   and upper(version_id) like :version';
            l_query_str := replace(l_query_str, ':dblink', l_dblink); -- can't bind
            open l_cursor
             for l_query_str
           using l_src_office_id,
                 l_location,
                 l_parameter,
                 l_param_type,
                 l_interval,
                 l_duration,
                 l_version;
      end if;
      loop
         fetch l_cursor into l_rec;
         exit when l_cursor%notfound;
         if l_first then
            l_first := false;
         else
            append_clob(cwms_util.record_separator);
         end if;
         append_clob(
            '' || l_rec.ts_code
            || cwms_util.field_separator
            || l_rec.interval_utc_offset
            || cwms_util.field_separator
            ||
            case l_rec.subcwms_id is null
               when true then
                  l_rec.cwms_id
               else
                  l_rec.cwms_id || '-' || l_rec.subcwms_id
            end
            || '.' ||
            case l_rec.subparameter_id is null
               when true then
                  l_rec.parameter_id
               else
                  l_rec.parameter_id || '-' || l_rec.subparameter_id
            end
            || '.' || l_rec.parameter_type_id
            || '.' || l_rec.interval_id
            || '.' || l_rec.duration_id
            || '.' || l_rec.version);
      end loop;
   end loop;

   dbms_lob.close(l_clob);
   return l_clob;

end get_ts_codes;

--------------------------------------------------------------------------------
-- POPULATE_TSIDS
--
-- Only call this if you have manually edited the REMOTE_OFFICES and/or
-- REMOTE_TSID_MASKS tables.
--------------------------------------------------------------------------------
procedure populate_tsids(
   p_office_id in varchar2)
is
  l_dblink        varchar2(31);
  l_cwms_ver      varchar2(3);
  l_ts_code       integer;
  l_tsid          varchar2(31);
  l_clob          clob;
  l_data          str_tab_tab_t;
  l_masks         varchar2(32767);
  l_parts         str_tab_t;
  l_src_office_id varchar2(16);
  l_dst_office_id varchar2(16);
begin
   l_parts := cwms_util.split_text(upper(p_office_id), '/', 1);
   l_src_office_id := l_parts(1);
   l_dst_office_id := l_parts(l_parts.count);
   ---------------------------
   -- get the database link --
   ---------------------------
   select dblink,
          cwms_ver
     into l_dblink,
          l_cwms_ver
     from remote_offices
    where src_office_id = l_src_office_id
      and dst_office_id = l_dst_office_id;
   ------------------------
   -- get the tsid masks --
   ------------------------
   for rec in (select mask from remote_tsid_masks where dblink = l_dblink) loop
      l_masks := l_masks || rec.mask || ',';
   end loop;
   l_masks := substr(l_masks, 1, length(l_masks) - 1); -- trim trailing ','
   --------------------------------
   -- get the tsids and ts codes --
   --------------------------------
   l_clob := get_ts_codes(p_office_id, l_masks);
   l_data := cwms_util.parse_clob_recordset(l_clob);
   cwms_msg.log_db_message(
      'remote_query.populate_tsids',
      cwms_msg.msg_level_detailed,
      '' || l_data.count
      || ' matching timeseries ids retrieved from '
      || upper(l_src_office_id)
      || ' through '
      || l_dblink);
   ------------------------
   -- populate the table --
   ------------------------
   delete from remote_tsids where dblink = l_dblink;
   for i in 1..l_data.count loop
      insert into remote_tsids values (l_dblink, l_data(i)(1), l_data(i)(2), l_data(i)(3));
   end loop;
   commit;
end populate_tsids;

--------------------------------------------------------------------------------
-- CREATE_LOCATIONS
--
-- Only call this if you have manually edited the REMOTE_OFFICES and/or
-- REMOTE_TSID_MASKS tables.
--------------------------------------------------------------------------------
procedure create_locations(
   p_office_id in varchar2)
is
   type locations_collection_t is table of boolean index by varchar2(49);
   type tz_collections_t is table of varchar2(28) index by varchar2(3);
   type loc_rec_t is record (
          base_location_id  varchar2(16),
          sub_location_id   varchar2(48),
          location_type     varchar2(16),
          elevation         number,
          elevation_unit    varchar2(16),
          vertical_datum    varchar2(16),
          latitude          number,
          longitude         number,
          horizontal_datum  varchar2(16),
          public_name       varchar2(32),
          long_name         varchar2(80),
          description_1     varchar2(512),
          description_2     varchar2(512),
          time_zone_code    number,
          county_code       number,
          active_flag       varchar2(1));
   type loc2_rec_t is record(
         time_zone_name varchar2(28),
         county_name    varchar2(40),
         state_initial  varchar2(2));
   location_already_exists exception;
   pragma exception_init (location_already_exists, -20026);
   l_src_office_id varchar2(16);
   l_dst_office_id varchar2(16);
   l_parts         str_tab_t;
   l_dblink        varchar2(31);
   l_cwms_ver      varchar2(3);
   l_location      varchar2(49);
   l_locations     locations_collection_t;
   l_query_str     varchar2(32767);
   l_tz_query_str  varchar2(32767);
   l_st_query_str  varchar2(32767);
   l_loc_str       varchar2(32767);
   l_loc_cur       sys_refcursor;
   l_subloc_cur    sys_refcursor;
   l_loc_rec       loc_rec_t;
   l_loc2_rec      loc2_rec_t;
   l_new_tz        tz_collections_t;
begin
   l_parts := cwms_util.split_text(upper(p_office_id), '/', 1);
   l_src_office_id := l_parts(1);
   l_dst_office_id := l_parts(l_parts.count);
   -------------------------------------------------
   -- set up the 1.5 -> 2.0 time zone transitions --
   -------------------------------------------------
   l_new_tz('ACT') := 'Australia/Adelaide';
   l_new_tz('AET') := 'Australia/Sydney';
   l_new_tz('AGT') := 'America/Buenos_Aires';
   l_new_tz('ART') := 'Africa/Cairo';
   l_new_tz('AST') := 'America/Anchorage';
   l_new_tz('BET') := 'Brazil/East';
   l_new_tz('BST') := 'Asia/Dhaka';
   l_new_tz('CAT') := 'Etc/GMT+1';
   l_new_tz('CNT') := 'Canada/Newfoundland';
   l_new_tz('CST') := 'America/Chicago';
   l_new_tz('CTT') := 'Asia/Hong_Kong';
   l_new_tz('EAT') := 'Africa/Nairobi';
   l_new_tz('ECT') := 'CET';
   l_new_tz('EET') := 'EET';
   l_new_tz('EST') := 'America/New_York';
   l_new_tz('GMT') := 'UTC';
   l_new_tz('HST') := 'Pacific/Honolulu';
   l_new_tz('IET') := 'America/Indianapolis';
   l_new_tz('IST') := 'Asia/Calcutta';
   l_new_tz('JST') := 'Japan';
   l_new_tz('MIT') := 'Pacific/Midway';
   l_new_tz('MST') := 'America/Denver';
   l_new_tz('NET') := 'Asia/Dubai';
   l_new_tz('NST') := 'Pacific/Auckland';
   l_new_tz('PLT') := 'Asia/Karachi';
   l_new_tz('PNT') := 'America/Phoenix';
   l_new_tz('PRT') := 'America/Puerto_Rico';
   l_new_tz('PST') := 'America/Los_Angeles';
   l_new_tz('SST') := 'Pacific/Noumea';
   l_new_tz('UNK') :=  null;
   l_new_tz('VST') := 'Asia/Bangkok';
   ---------------------------
   -- get the database link --
   ---------------------------
   select dblink,
          cwms_ver
     into l_dblink,
          l_cwms_ver
     from remote_offices
    where src_office_id = l_src_office_id
      and dst_office_id = l_dst_office_id;
   -----------------------------------------
   -- collect the location ids from tsids --
   -----------------------------------------
   for rec in (select ts_id from remote_tsids where dblink = l_dblink) loop
      l_location := upper(cwms_util.split_text(rec.ts_id, '.')(1));
      if instr(l_location, '-') = 0 then
         l_location := l_location || '-';
      end if;
      if not l_locations.exists(l_location) then
         l_loc_str := l_loc_str || l_location || ',';
         l_locations(l_location) := true;
      end if;
   end loop;
   l_loc_str := substr(l_loc_str, 1, length(l_loc_str) - 1);
   -------------------------------------------------------------------------------------
   -- loop through locations in remote database and create location in local database --
   -------------------------------------------------------------------------------------
   if l_cwms_ver = '1.5' then
      ----------------------
      -- CWMS 1.5 queries --
      ----------------------
      l_query_str :=
         'select distinct n.cwms_id base_location_id,
                 t.subcwms_id sub_location_id,
                 l.location_type,
                 case l.elevation
                    when -3.4028234663852886E38 then null
                    else l.elevation
                 end elevation,
                 ''ft'' elevation_unit,
                 l.vertical_datum,
                 case l.latitude
                    when -3.4028234663852886E38 then null
                    else l.latitude
                 end latitude,
                 case l.longitude
                    when -3.4028234663852886E38 then null
                    else l.longitude
                 end longitude,
                 null horizontal_datum,
                 n.public_name,
                 n.long_name,
                 n.description description_1,
                 l.description description_2,
                 l.zone_code time_zone_code,
                 l.county_code,
                 ''T'' active_flag
            from cwms.at_office@:dblink o,
                 cwms.at_cwms_name@:dblink n,
                 cwms.at_cwms_ts_spec@:dblink t,
                 cwms.at_point_location@:dblink p,
                 cwms.at_physical_location@:dblink l
           where o.office_id = :office
             and n.office_code = o.office_code
             and n.cwms_id_uc || ''-'' || upper(t.subcwms_id) in (:locations)
             and t.location_code = l.location_code
             and p.cwms_code = n.cwms_code
             and l.location_code = p.location_code';
      l_tz_query_str :=
         'select zone_id
            into :name
            from cwms.rt_time_zone@:dblink
           where zone_code = :code';
      l_st_query_str :=
         'select c.name,
                 s.state_initial
            into :county,
                 :state
            from cwms.rt_county@:dblink c,
                 cwms.rt_state@:dblink s
           where c.county_code = :code
             and s.state_code = c.state_code';
   else
      ----------------------
      -- CWMS 2.0 queries --
      ----------------------
      l_query_str :=
         'select b.base_location_id,
                 l.sub_location_id,
                 l.location_type,
                 l.elevation,
                 ''m'' elevation_unit,
                 l.vertical_datum,
                 l.latitude,
                 l.longitude,
                 l.horizontal_datum,
                 l.public_name,
                 l.long_name,
                 null description_1,
                 l.description description_2,
                 l.time_zone_code,
                 l.county_code,
                 l.active_flag
            from '||'&cwms_schema'||'.cwms_office@:dblink o,
                 '||'&cwms_schema'||'.at_base_location@:dblink b,
                 '||'&cwms_schema'||'.at_physical_location@:dblink l
           where o.office_id = :office
             and b.db_office_code = o.office_code
             and upper(b.base_location_id) || ''-'' || upper (l.sub_location_id) in (:locations)
             and l.base_location_code = b.base_location_code';
      l_tz_query_str :=
         'select time_zone_name
            into :name
            from '||'&cwms_schema'||'.cwms_time_zone@:dblink
           where time_zone_code = :code';
      l_st_query_str :=
         'select c.county_name,
                 s.state_initial
            into :county,
                 :state
            from '||'&cwms_schema'||'.cwms_county@:dblink c,
                 '||'&cwms_schema'||'.cwms_state@:dblink s
           where c.county_code = :code
             and s.state_code = c.state_code';
   end if;
   l_query_str    := replace(l_query_str,    ':dblink', l_dblink); -- can't bind
   l_tz_query_str := replace(l_tz_query_str, ':dblink', l_dblink); -- can't bind
   l_st_query_str := replace(l_st_query_str, ':dblink', l_dblink); -- can't bind
   open l_loc_cur for l_query_str using l_src_office_id, l_loc_str;
   loop
      ---------------------------
      -- get the next location --
      ---------------------------
      fetch l_loc_cur into l_loc_rec;
      exit when l_loc_cur%notfound;
      ---------------------------
      -- get supplemental info --
      ---------------------------
      if l_loc_rec.time_zone_code is null then
         l_loc2_rec.time_zone_name := null;
      else
         execute
            immediate l_tz_query_str
                 into l_loc2_rec.time_zone_name
                using l_loc_rec.time_zone_code;
         if l_cwms_ver = '1.5' then
            begin
               l_loc2_rec.time_zone_name := l_new_tz(l_loc2_rec.time_zone_name);
            exception
               when no_data_found then
                  l_loc2_rec.time_zone_name := null;
            end;
         end if;
      end if;
      if l_loc_rec.county_code is null then
         l_loc2_rec.county_name    := null;
         l_loc2_rec.state_initial  := null;
      else
         execute
            immediate l_st_query_str
                 into l_loc2_rec.county_name,
                      l_loc2_rec.state_initial
                using l_loc_rec.county_code;
      end if;
      -------------------------------
      -- create the local location --
      -------------------------------
      l_location :=
         case l_loc_rec.sub_location_id is null
            when true then l_loc_rec.base_location_id
            else l_loc_rec.base_location_id || '-' || l_loc_rec.sub_location_id
         end;
      cwms_msg.log_db_message(
         'remote_query.create_locations',
         cwms_msg.msg_level_detailed,
         'Creating location ' || l_location);
      begin
         cwms_loc.create_location(
            l_location,
            l_loc_rec.location_type,
            l_loc_rec.elevation,
            l_loc_rec.elevation_unit,
            l_loc_rec.vertical_datum,
            l_loc_rec.latitude,
            l_loc_rec.longitude,
            l_loc_rec.horizontal_datum,
            l_loc_rec.public_name,
            l_loc_rec.long_name,
            nvl(l_loc_rec.description_2, l_loc_rec.description_1),
            l_loc2_rec.time_zone_name,
            l_loc2_rec.county_name,
            l_loc2_rec.state_initial,
            l_loc_rec.active_flag,
            upper(l_dst_office_id));
      exception
         when location_already_exists then null;
      end;
   end loop;
   close l_loc_cur;
   commit;
end create_locations;

--------------------------------------------------------------------------------
-- SET_OFFICE
--
-- Populates the REMOTE_OFFICES and REMOTE_TSID_MASKS tables and calls
-- POPULATE_TSIDS
--------------------------------------------------------------------------------
procedure set_office(
   p_office_id  in varchar2,  -- 'LRH', 'SPK', etc... or SRC/DST (e.g. 'NWD/NWO')
   p_dblink     in varchar2,  -- database link
   p_cwms_ver   in varchar2,  -- must be '1.5' or '2.0'
   p_tsid_masks in varchar2)  -- comma-separated list of tsid masks
is
   l_dst_office_id  varchar2(16);
   l_src_office_id  varchar2(16);
   l_count      integer;
   l_masks      str_tab_t;
   l_mask_parts str_tab_t;
   l_ts_code    integer;
begin
   ------------------
   -- sanity check --
   ------------------
   if p_dblink is null then
      raise_application_error(
         -20999,
         'Database link must not be null.',
         false);
   end if;
   select count(*)
     into l_count
     from dba_db_links
    where upper(db_link) = upper(p_dblink);
   if l_count = 0 then
      raise_application_error(
         -20999,
         'Database link ' || p_dblink || ' does not exist.',
         false);
   end if;
   if p_cwms_ver != '1.5' and p_cwms_ver != '2.0' then
      raise_application_error(
         -20999,
         'CWMS Version must be ''1.5'' or ''2.0''.',
         false);
   end if;
   l_masks := cwms_util.split_text(upper(p_office_id), '/', 1);
   l_src_office_id := l_masks(1);
   l_dst_office_id := l_masks(l_masks.count);
   select count(*) into l_count from cwms_office where office_id = l_src_office_id;
   if l_count = 0 then
      raise_application_error(
         -20999,
         'Office ''' || l_src_office_id || ''' is not a valid CWMS office.',
         false);
   end if;
   select count(*) into l_count from cwms_office where office_id = l_dst_office_id;
   if l_count = 0 then
      raise_application_error(
         -20999,
         'Office ''' || l_dst_office_id || ''' is not a valid CWMS office.',
         false);
   end if;
   if p_tsid_masks is not null then
      l_masks := cwms_util.split_text(p_tsid_masks, ',');
      for i in 1..l_masks.count loop
         l_mask_parts := cwms_util.split_text(l_masks(i), '.');
         if l_mask_parts.count != 6 then
            raise_application_error(
               -20999,
               'TSID mask must contain 6 parts separated by periods: '
               || l_masks(i),
               false);
         end if;
      end loop;
   end if;
   --------------------------
   -- now insert or update --
   --------------------------
   select count(*) 
     into l_count 
     from remote_offices 
    where src_office_id = l_src_office_id
      and dst_office_id = l_dst_office_id;
   if l_count = 0 then
      insert
        into remote_offices
      values (l_src_office_id, l_dst_office_id, p_dblink, p_cwms_ver);
   else
      update remote_offices
         set dblink = p_dblink,
             cwms_ver = p_cwms_ver
       where src_office_id = l_src_office_id
         and dst_office_id = l_dst_office_id;
   end if;
   delete
     from remote_tsid_masks
    where dblink = p_dblink;
   if l_masks is not null then
      for i in 1..l_masks.count loop
         insert
           into remote_tsid_masks
         values(p_dblink, l_masks(i));
      end loop;
   end if;
   ------------------------------------------------------------------------
   -- finally, get the remote tsids and create local locations and tsids --
   ------------------------------------------------------------------------
   cwms_msg.log_db_message(
      'remote_query.set_office',
      cwms_msg.msg_level_normal,
      l_dst_office_id
      || ': Creating local queues');
   cwms_msg.create_queues(l_dst_office_id);      
   cwms_msg.log_db_message(
      'remote_query.set_office',
      cwms_msg.msg_level_normal,
      l_dst_office_id
      || ': Retrieving remote timeseires ids');
   populate_tsids(p_office_id);
   cwms_msg.log_db_message(
      'remote_query.set_office',
      cwms_msg.msg_level_normal,
      l_dst_office_id
      || ': Creating local locations');
   create_locations(p_office_id);
   cwms_msg.log_db_message(
      'remote_query.set_office',
      cwms_msg.msg_level_normal,
      l_dst_office_id
      || ': Creating local timeseries ids');
   l_ts_code := -1;
   for rec in (select ts_id from remote_tsids where dblink = p_dblink) loop
      cwms_ts.create_ts_code(
         l_ts_code,
         rec.ts_id,
         null, -- utc offset
         null, -- interval forward
         null, -- interval backward
         'F',  -- versioned
         'T',  -- active
         'F',  -- fail if exists
         l_dst_office_id);
   end loop;
   commit;
   cwms_msg.log_db_message(
      'remote_query.set_office',
      cwms_msg.msg_level_normal,
      l_dst_office_id
      || ': Done');

end set_office;

--------------------------------------------------------------------------------
-- BUILD_RETRIEVE_TS_QUERY
--------------------------------------------------------------------------------
procedure build_retrieve_ts_query (
   p_cursor          out sys_refcursor,
   p_cwms_ts_id      in  varchar2,
   p_ts_code         in  integer,
   p_offset          in  integer,
   p_start_time      in  date,
   p_end_time        in  date,
   p_cwms_ver        in  varchar2,
   p_dblink          in  varchar2
   )
is
   l_cursor           sys_refcursor;
   l_interval_id      varchar2(16);
   l_interval         number;
   l_offset           number          := p_offset / 60; -- convert to minutes
   l_trim             boolean         := false;
   l_start_inclusive  boolean         := true;
   l_end_inclusive    boolean         := true;
   l_previous         boolean         := false;
   l_next             boolean         := false;
   l_version_date     date            := null;
   l_max_version      boolean         := false;
   l_reg_start_time   date;
   l_reg_end_time     date;
   l_query_str        varchar2(4000);
   l_start_str        varchar2(32);
   l_end_str          varchar2(32);
   l_reg_start_str    varchar2(32);
   l_reg_end_str      varchar2(32);
   l_missing          number          := 5;  -- MISSING quality code
   l_date_format      varchar2(32)    := 'yyyy/mm/dd-hh24.mi.ss';

begin
   if p_cwms_ver = '1.5' then
      --------------
      -- CWMS 1.5 --
      --------------
      l_query_str :=
         'select date_time,
                 value,
                 quality "QUALITY_CODE"
            from cwms.at_time_series_value@:dblink
           where ts_code    =  :ts_code
             and date_time  >= :start_time
             and date_time  <= :end_time
        order by date_time asc';
      l_query_str := replace(l_query_str, ':dblink',  p_dblink); -- can't bind
      open l_cursor
       for l_query_str
     using p_ts_code,
           p_start_time,
           p_end_time;
   else
      --------------
      -- CWMS 2.0 --
      --------------
      l_interval_id := cwms_util.split_text(p_cwms_ts_id,'.')(4);
      select interval into l_interval from cwms_interval where interval_id = l_interval_id;
      if l_interval = 0 then
         l_reg_start_time := null;
         l_reg_end_time   := null;
      else
         if p_offset = cwms_util.utc_offset_undefined then
            l_reg_start_time := cwms_ts.get_time_on_after_interval(p_start_time, null, l_interval);
            l_reg_end_time   := cwms_ts.get_time_on_before_interval(p_end_time, null, l_interval);
         else
            l_reg_start_time := cwms_ts.get_time_on_after_interval(p_start_time, l_offset, l_interval);
            l_reg_end_time   := cwms_ts.get_time_on_before_interval(p_end_time, l_offset, l_interval);
        end if;
      end if;
      --
      -- change interval from minutes to days
      --
      l_interval := l_interval / 1440;
      --
      -- build the query string - for some reason the time zone must be a
      -- string literal and bind variables are problematic
      --
      if l_interval > 0 then
         --
         -- regular time series
         --
         if mod(l_interval, 30) = 0 or mod(l_interval, 365) = 0 then
            --
            -- must use calendar math
            --
            -- change interval from days to months
            --
            if mod(l_interval, 30) = 0 then
               l_interval := l_interval / 30;
            else
               l_interval := l_interval / 365 * 12;
            end if;
            l_query_str :=
               'select v.date_time,
                       value,
                       nvl(quality_code, :missing) "QUALITY_CODE"
                 from (
                      select date_time,
                             max(value) keep(dense_rank last order by version_date) "VALUE",
                             max(quality_code) keep(dense_rank last order by version_date) "QUALITY_CODE"
                        from '||'&cwms_schema'||'.av_tsv@:dblink
                       where ts_code    =  :ts_code
                         and date_time  >= :start_time
                         and date_time  <= :end_time
                         and start_date <= :end_time
                         and end_date   >  :start_time
                    group by date_time
                      ) v
                      right outer join
                      (
                      select add_months(:reg_start, (level-1) * :interval) date_time
                        from dual
                       where :reg_start is not null
                  connect by level <= months_between(:reg_end, :reg_start) / :interval + 1
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
         else
            --
            -- can use date arithmetic
            --
            l_query_str :=
               'select  v.date_time,
                        value,
                        nvl(quality_code, :missing) "QUALITY_CODE"
                   from (
                        select date_time,
                               max(value) keep(dense_rank last order by version_date) "VALUE",
                               max(quality_code) keep(dense_rank last order by version_date) "QUALITY_CODE"
                          from '||'&cwms_schema'||'.av_tsv@:dblink
                         where ts_code    =  :ts_code
                           and date_time  >= :start_time
                           and date_time  <= :end_time
                           and start_date <= :end_time
                           and end_date   >  :start_time
                      group by date_time
                        ) v
                        right outer join
                        (
                        select :reg_start + (level-1) * :interval date_time
                          from dual
                         where :reg_start is not null
                    connect by level <= round((:reg_end - :reg_start) / :interval + 1)
                        ) t
                        on v.date_time = t.date_time
                        order by t.date_time asc';
         end if;
         l_query_str := replace(l_query_str, ':dblink',  p_dblink); -- can't bind
         open l_cursor
          for l_query_str
        using l_missing,
              p_ts_code,
              p_start_time,
              p_end_time,
              p_end_time,
              p_start_time,
              l_reg_start_time,
              l_interval,
              l_reg_start_time,
              l_reg_end_time,
              l_reg_start_time,
              l_interval;
      else
        --
        -- irregular time series
        --
         l_query_str :=
            'select date_time,
                    max(value) keep(dense_rank last order by version_date) "VALUE",
                    max(quality_code) keep(dense_rank last order by version_date) "QUALITY_CODE"
               from '||'&cwms_schema'||'.av_tsv@:dblink
              where ts_code    =  :ts_code
                and date_time  >= :start_time
                and date_time  <= :end_time
                and start_date <= :end_time
                and end_date   >  :start_time
           group by date_time
           order by date_time asc';
            l_query_str := replace(l_query_str, ':dblink',  p_dblink); -- can't bind
            open l_cursor
             for l_query_str
           using p_ts_code,
                 p_start_time,
                 p_end_time,
                 p_end_time,
                 p_start_time;
      end if;
   end if;

   p_cursor := l_cursor;

end build_retrieve_ts_query;

--------------------------------------------------------------------------------
-- RETRIEVE_TIMESERIES
--
-- Retrieves time series data from the specified office(s) for the specified
-- date range.  The p_office_id_masks parameter can be used to group offices
-- (e.g., 'SW_,SP_' would retrieve data for all Southwestern and South Pacific
-- offices, '%' would retrieve all offices, etc...)
--------------------------------------------------------------------------------
procedure retrieve_timeseries(
   p_offices_processed out integer,
   p_tsids_processed   out integer,
   p_values_retrieved  out integer,
   p_office_id_masks   in  varchar2,
   p_start_time_utc    in date,
   p_end_time_utc      in date default null) -- null = current time
is
   type ts_rec15_t is record(
      date_time date,
      value     number,
      quality   raw(4)
      );
   type ts_rec20_t is record(
      date_time date,
      value     binary_double,
      quality   integer
      );
   l_offices_processed integer := 0;
   l_tsids_processed   integer := 0;
   l_values_retrieved  integer := 0;
   l_office_id_masks   str_tab_t := cwms_util.split_text(upper(p_office_id_masks), ',');
   l_office_id         varchar2(16);
   l_end_time_utc      date := nvl(p_end_time_utc, cast(systimestamp at time zone 'UTC' as date));
   l_query_str         varchar2(32767);
   l_ts_rec15          ts_rec15_t;
   l_ts_rec20          ts_rec20_t;
   l_ts_cur            sys_refcursor;
   l_tsv_array         tsv_array := new tsv_array();
   l_quality           integer;
   l_missing           integer := 5;
   l_not_screened      integer := 0;
begin
   --
   -- If the following line is omitted, Oracle often pukes with an internal error
   -- when executing the queries across the dblinks.  I don't know if using this 
   -- setting is the culprit, but the cursors have NULL times for missing data in
   -- regular time series.  The values should be NULL, but not the times.  I added
   -- 'continue when date_time is null' in the loops below to deal with it.  Other-
   -- wise the store_ts() procedure pukes.
   --
   -- MDP 07-JUL-2009
   -- 
   execute immediate 'alter session set "_optimizer_connect_by_cost_based"=false';
   -------------------------------------------
   -- loop through office masks and offices --
   -------------------------------------------
   cwms_msg.log_db_message(
      'remote_query.retrieve_timeseries',
      cwms_msg.msg_level_normal,
      'Retrieving remote timeseries data for interval '
      || to_char(p_start_time_utc, 'yyyy/mm/dd hh24:mi:ss')
      || ' through '
      || to_char(l_end_time_utc, 'yyyy/mm/dd hh24:mi:ss'));
   for i in 1..l_office_id_masks.count loop
      for ofc_rec in (
         select dst_office_id,
                dblink,
                cwms_ver
           from remote_offices
          where dst_office_id like l_office_id_masks(i))
      loop
         l_offices_processed := l_offices_processed + 1;
         cwms_msg.log_db_message(
            'remote_query.retrieve_timeseries',
            cwms_msg.msg_level_normal,
            'Retrieving timeseries data for office '
            || ofc_rec.dst_office_id
            || ' through dblink '
            || ofc_rec.dblink);
         ------------------------
         -- loop through tsids --
         ------------------------
         for tsid_rec in (
            select ts_code,
                   interval_utc_offset,
                   ts_id
              from remote_tsids
             where dblink = ofc_rec.dblink)
         loop
            l_tsids_processed := l_tsids_processed + 1;
            cwms_msg.log_db_message(
               'remote_query.retrieve_timeseries',
               cwms_msg.msg_level_detailed,
               'Retrieving timeseries data for '
               || tsid_rec.ts_id);
            begin
               build_retrieve_ts_query (
                  l_ts_cur,
                  tsid_rec.ts_id,
                  tsid_rec.ts_code,
                  tsid_rec.interval_utc_offset,
                  p_start_time_utc,
                  l_end_time_utc,
                  ofc_rec.cwms_ver,
                  ofc_rec.dblink);
            exception
               when others then
                  cwms_msg.log_db_message(
                     'remote_query.retrieve_timeseries',
                     cwms_msg.msg_level_normal,
                     'Error ' || sqlcode || ' on ' || tsid_rec.ts_id || ': ' || sqlerrm);
                  dbms_output.put_line('Error ' || sqlcode || ' on ' || tsid_rec.ts_id || ': ' || sqlerrm);
                  dbms_output.put_line(l_query_str);
                  continue;
            end;
            -----------------------------------------
            -- loop through the time series values --
            -----------------------------------------
            l_tsv_array.delete;
            if ofc_rec.cwms_ver = '1.5' then
               loop
                  fetch l_ts_cur into l_ts_rec15;
                  exit when l_ts_cur%notfound;
                  continue when l_ts_rec15.date_time is null;
                  l_tsv_array.extend;
                  if l_ts_rec15.value < -1.0e38 then
                    l_ts_rec15.value := null;
                  end if;
                  if l_ts_rec15.quality is null then
                     if l_ts_rec15.value is null then
                        l_quality := l_missing;
                     else
                        l_quality := l_not_screened;
                     end if;
                  else
                     l_quality := to_number(rawtohex(l_ts_rec15.quality), 'XXXXXXXX');
                  end if;
                  l_tsv_array(l_tsv_array.count) := new tsv_type(
                     from_tz(cast(l_ts_rec15.date_time as timestamp), 'UTC'),
                     cast(l_ts_rec15.value as binary_double),
                     l_quality);
               end loop;
            else
               loop
                  fetch l_ts_cur into l_ts_rec20;
                  exit when l_ts_cur%notfound;
                  continue when l_ts_rec20.date_time is null;
                  l_tsv_array.extend;
                  l_tsv_array(l_tsv_array.count) := new tsv_type(
                     from_tz(cast(l_ts_rec20.date_time as timestamp), 'UTC'),
                     l_ts_rec20.value,
                     l_ts_rec20.quality);
               end loop;
            end if;
            close l_ts_cur;
            cwms_msg.log_db_message(
               'remote_query.retrieve_timeseries',
               cwms_msg.msg_level_detailed,
               '' || l_tsv_array.count
               || ' timeseries values retrieved for '
               || tsid_rec.ts_id);
            if l_tsv_array.count > 0 then
               l_values_retrieved := l_values_retrieved + l_tsv_array.count;
               -------------------------------------------------
               -- store the time series in the local database --
               -------------------------------------------------
               begin
                  cwms_ts.store_ts (
                     tsid_rec.ts_id,
                     cwms_ts.get_db_unit_id(tsid_rec.ts_id),
                     l_tsv_array,
                     cwms_util.delete_insert,
                     'F',
                     cwms_util.non_versioned,
                     ofc_rec.dst_office_id);
               exception
                  when others then
                     cwms_msg.log_db_message(
                        'remote_query.retrieve_timeseries',
                        cwms_msg.msg_level_normal,
                        'Error during interval: ' || sqlerrm);
               end;
            end if;
         end loop;
      end loop;
   end loop;
   execute immediate 'alter session set "_optimizer_connect_by_cost_based"=true';
   cwms_msg.log_db_message(
      'remote_query.retrieve_timeseries',
      cwms_msg.msg_level_normal,
      'Remote timeseries data retrieval completed for interval '
      || to_char(p_start_time_utc, 'yyyy/mm/dd hh24:mi:ss')
      || ' through '
      || to_char(l_end_time_utc, 'yyyy/mm/dd hh24:mi:ss'));
   p_offices_processed := l_offices_processed;
   p_tsids_processed   := l_tsids_processed;
   p_values_retrieved  := l_values_retrieved;
end retrieve_timeseries;

--------------------------------------------------------------------------------
-- RETRIEVE_AND_LOG
--
-- Calls RETRIEVE_TIMESERIES and logs start time, end time and items processed
--------------------------------------------------------------------------------
procedure retrieve_and_log(
   p_office_id_masks   in varchar2,
   p_start_time_utc    in date,
   p_end_time_utc      in date default null) -- null = current time
is   
   l_offices_processed  integer;
   l_tsids_processed    integer;
   l_values_retrieved   integer;
   l_end_time_utc       date := nvl(p_end_time_utc, cast(systimestamp at time zone 'UTC' as date)); 
begin
   cwms_msg.log_db_message(
      'retrieve timeseries', 
      cwms_msg.msg_level_normal,
      to_char(systimestamp) 
      || ' Starting retrieval for offices ('
      || p_office_id_masks
      || ') and time window '
      || to_char(p_start_time_utc, 'dd-Mon-yyyy hh24mi')
      || ' to '
      || to_char(l_end_time_utc, 'dd-Mon-yyyy hh24mi'));
      
   retrieve_timeseries(
      l_offices_processed,
      l_tsids_processed,
      l_values_retrieved,
      p_office_id_masks,
      p_start_time_utc,
      p_end_time_utc);
      
   cwms_msg.log_db_message(
      'retrieve timeseries', 
      cwms_msg.msg_level_normal,
      to_char(systimestamp) 
      || ' Retrieved '
      || l_values_retrieved
      || ' values from '
      || l_tsids_processed
      || ' tsids in '
      || l_offices_processed
      || ' offices');
      
end retrieve_and_log;

   
--------------------------------------------------------------------------------
-- RETRIEVE_AND_LOG
--
-- Calls RETRIEVE_TIMESERIES and logs start time, end time and items processed
--------------------------------------------------------------------------------
procedure retrieve_and_log(
   p_office_id_masks  in varchar2,
   p_days_to_retrieve in number)
is
   l_end_time   date := cast(systimestamp at time zone 'UTC' as date);
   l_start_time date := l_end_time - p_days_to_retrieve;
begin
   retrieve_and_log(p_office_id_masks, l_start_time, l_end_time);
end retrieve_and_log;   
   
procedure retrieve_job
is
   l_now date := cast(systimestamp at time zone 'UTC' as date);
begin
   retrieve_and_log('%', l_now - &retrieve_ts_minutes / 1440, l_now);
end retrieve_job;   


end;
/
show errors
commit;

whenever sqlerror continue

drop database link &office_id._cwms_remote;
 
whenever sqlerror exit sql.sqlcode

create database link &office_id._cwms_remote connect to cwms identified by &cwms_pass using '&remote_db_url';

declare
   l_job_name varchar2(30) := 'get_remote_cwms_data'; 
begin
   begin
      dbms_scheduler.stop_job(l_job_name, true);
   exception
      when others then null;
   end;
   begin
      dbms_scheduler.drop_job(l_job_name);
   exception
      when others then null;
   end;
   dbms_scheduler.create_job(
       job_name             => l_job_name,
       job_type             => 'stored_procedure',
       job_action           => 'remote_query.retrieve_job',
       start_date           => null,
       repeat_interval      => 'freq=minutely; interval=&retrieve_job_interval',
       end_date             => null,
       job_class            => 'default_job_class',
       enabled              => true,
       auto_drop            => false,
       comments             => 'Pulls specified time series data from remote CWMS system'
      );
end;   

commit;   
   


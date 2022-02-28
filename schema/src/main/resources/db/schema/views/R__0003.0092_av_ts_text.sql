/**
 * Displays time series text, whether associated with a value time series or not
 *
 * @since CWMS 3.2
 *
 * @field office_id           The office that owns the time series
 * @field location_id         The location for the time series
 * @field cwms_ts_id          The time series identifier
 * @field text_time_series    A flag (T/F) indicating whether the time series is text only (parameter = ''Text'')
 * @field date_time_utc       The date/time the value+text or text is for
 * @field version_date_utc    The version date/time of the time series
 * @field data_entry_date_utc The date/time the value (value+text) or first text (text only) was stored to the database
 * @field attribute           A numeric value (can be used for sorting multiple text values for a specified date_time/version)
 * @field si_value            The SI unit value for value time series (parameter not in (''Text'', ''Binary'')
 * @field si_unit             The SI unit of the value for value time series (parameter not in (''Text'', ''Binary'')
 * @field en_value            The English unit value for value time series (parameter not in (''Text'', ''Binary'')
 * @field en_unit             The English unit of the value for value time series (parameter not in (''Text'', ''Binary'')
 * @field quality_code        The quality code of the value for value time series (parameter not in (''Text'', ''Binary'')
 * @field std_text_id         The standard text ID if the text is standard
 * @field text_value          The (standard or non-standard) text
 * @field aliased_item        Character value specifying what, if anything, in the CWMS_TS_ID field is aliased
 * @field loc_alias_category  The location alias category if the location ID or base location ID is aliased
 * @field loc_alias_group     The location alias group if the location ID or base location ID is aliased
 * @field ts_alias_category   The time series alias category if the time series ID is aliased
 * @field ts_alias_group      The time series alias group if the time series ID is aliased
 * @field office_code         The numeric code identifying the office that owns the time seires
 * @field location_code       The numeric code identifying the location for the time series
 * @field ts_code             The numeric code identifying the time series
 * @field clob_code           The code identifying the non-standard or long standard text
 */
create or replace force view av_ts_text (
   office_id,
   location_id,
   cwms_ts_id,
   text_time_series,
   date_time_utc,
   version_date_utc,
   data_entry_date_utc,
   attribute,
   si_value,
   si_unit,
   en_value,
   en_unit,
   quality_code,
   std_text_id,
   text_value,
   aliased_item,
   loc_alias_category,
   loc_alias_group,
   ts_alias_category,
   ts_alias_group,
   office_code,
   location_code,
   ts_code,
   clob_code
)
as
select q1.office_id,
       v1.location_id,
       case
          when v1.aliased_item is null then q1.cwms_ts_id
          else v1.location_id||substr(q1.cwms_ts_id, instr(q1.cwms_ts_id, '.'))
       end as cwms_ts_id,
       case
          when cwms_util.split_text(q1.cwms_ts_id, 2, '.') = 'Text' then 'T'
          else 'F'
       end as text_time_series,
       q1.date_time_utc,
       q1.version_date_utc,
       q1.data_entry_date_utc,
       q1.attribute,
       cwms_util.convert_units(
          q1.value,
          cwms_util.get_default_units(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'SI'),
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'SI')) as si_value,
       cwms_display.retrieve_user_unit_f(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'SI') as si_unit,
       cwms_util.convert_units(
          q1.value,
          cwms_util.get_default_units(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'SI'),
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'EN')) as en_value,
       cwms_display.retrieve_user_unit_f(cwms_util.split_text(q1.cwms_ts_id, 2, '.'), 'EN') as en_unit,
       q1.quality_code,
       q1.std_text_id,
       q1.text_value,
       v1.aliased_item,
       v1.loc_alias_category,
       v1.loc_alias_group,
       null as ts_alias_category,
       null as ts_alias_group,
       q1.db_office_code as office_code,
       q1.location_code,
       q1.ts_code,
       q1.clob_code
  from (select q111.db_office_id as office_id,
               q111.cwms_ts_id,
               q111.date_time as date_time_utc,
               q111.version_date as version_date_utc,
               q111.data_entry_date as data_entry_date_utc,
               q111.attribute,
               q112.value,
               q112.quality_code,
               q111.std_text_id,
               nvl(q113.text_value, q111.std_text_id) as text_value,
               q111.db_office_code,
               q111.location_code,
               q111.ts_code,
               q113.clob_code
          from (select ts.db_office_id,
                       ts.cwms_ts_id,
                       tt.date_time,
                       tt.version_date,
                       tt.data_entry_date,
                       tt.attribute,
                       st.std_text_id,
                       ts.db_office_code,
                       ts.location_code,
                       tt.ts_code,
                       st.clob_code
                  from at_tsv_std_text tt,
                       at_std_text st,
                       at_cwms_ts_id ts
                 where ts.ts_code = tt.ts_code
                   and st.std_text_code = tt.std_text_code
               ) q111
               left outer join
               (select ts_code,
                       date_time,
                       version_date,
                       value,
                       quality_code
                  from av_tsv
               ) q112 on q112.ts_code = q111.ts_code and q112.date_time = q111.date_time and q112.version_date = q111.version_date
               left outer join
               (select clob_code,
                       value as text_value
                  from at_clob
               ) q113 on q113.clob_code = q111.clob_code
        union all
        select q121.db_office_id as office_id,
               q121.cwms_ts_id,
               q121.date_time as date_time_utc,
               q121.version_date as version_date_utc,
               q121.data_entry_date as data_entry_date_utc,
               q121.attribute,
               q122.value,
               q122.quality_code,
               q121.std_text_id,
               nvl(q123.text_value, q121.std_text_id) as text_value,
               q121.db_office_code,
               q121.location_code,
               q121.ts_code,
               q123.clob_code
          from (select ts.db_office_id,
                       ts.cwms_ts_id,
                       tt.date_time,
                       tt.version_date,
                       tt.data_entry_date,
                       tt.attribute,
                       null as std_text_id,
                       ts.db_office_code,
                       ts.location_code,
                       tt.ts_code,
                       tt.clob_code
                  from at_tsv_text tt,
                       at_cwms_ts_id ts
                 where ts.ts_code = tt.ts_code
               ) q121
               left outer join
               (select ts_code,
                       date_time,
                       version_date,
                       value,
                       quality_code
                  from av_tsv
               ) q122 on q122.ts_code = q121.ts_code and q122.date_time = q121.date_time and q122.version_date = q121.version_date
               left outer join
               (select clob_code,
                       value as text_value
                  from at_clob
               ) q123 on q123.clob_code = q121.clob_code
       ) q1
       join
       av_loc2 v1 on v1.location_code = q1.location_code and v1.unit_system = 'EN'
union all
select q2.office_id,
       v2.location_id,
       v2.cwms_ts_id,
       case
          when cwms_util.split_text(q2.cwms_ts_id, 2, '.') = 'Text' then 'T'
          else 'F'
       end as text_time_series,
       q2.date_time_utc,
       q2.version_date_utc,
       q2.data_entry_date_utc,
       q2.attribute,
       cwms_util.convert_units(
          q2.value,
          cwms_util.get_default_units(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'SI'),
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'SI')) as si_value,
       cwms_display.retrieve_user_unit_f(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'SI') as si_unit,
       cwms_util.convert_units(
          q2.value,
          cwms_util.get_default_units(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'SI'),
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'EN')) as en_value,
       cwms_display.retrieve_user_unit_f(cwms_util.split_text(q2.cwms_ts_id, 2, '.'), 'EN') as en_unit,
       q2.quality_code,
       q2.std_text_id,
       q2.text_value,
       v2.aliased_item,
       null asloc_alias_category,
       null asloc_alias_group,
       v2.ts_alias_category,
       v2.ts_alias_group,
       q2.db_office_code as office_code,
       q2.location_code,
       q2.ts_code,
       q2.clob_code
  from (select q211.db_office_id as office_id,
               q211.cwms_ts_id,
               q211.date_time as date_time_utc,
               q211.version_date as version_date_utc,
               q211.data_entry_date as data_entry_date_utc,
               q211.attribute,
               q212.value,
               q212.quality_code,
               q211.std_text_id,
               nvl(q213.text_value, q211.std_text_id) as text_value,
               q211.db_office_code,
               q211.location_code,
               q211.ts_code,
               q213.clob_code
          from (select ts.db_office_id,
                       ts.cwms_ts_id,
                       tt.date_time,
                       tt.version_date,
                       tt.data_entry_date,
                       tt.attribute,
                       st.std_text_id,
                       ts.db_office_code,
                       tt.ts_code,
                       ts.location_code,
                       st.clob_code
                  from at_tsv_std_text tt,
                       at_std_text st,
                       at_cwms_ts_id ts
                 where ts.ts_code = tt.ts_code
                   and st.std_text_code = tt.std_text_code
               ) q211
               left outer join
               (select ts_code,
                       date_time,
                       version_date,
                       value,
                       quality_code
                  from av_tsv
               ) q212 on q212.ts_code = q211.ts_code and q212.date_time = q211.date_time and q212.version_date = q211.version_date
               left outer join
               (select clob_code,
                       value as text_value
                  from at_clob
               ) q213 on q213.clob_code = q211.clob_code
        union all
        select q221.db_office_id as office_id,
               q221.cwms_ts_id,
               q221.date_time as date_time_utc,
               q221.version_date as version_date_utc,
               q221.data_entry_date as data_entry_date_utc,
               q221.attribute,
               q222.value,
               q222.quality_code,
               q221.std_text_id,
               nvl(q223.text_value, q221.std_text_id) as text_value,
               q221.db_office_code,
               q221.location_code,
               q221.ts_code,
               q223.clob_code
          from (select ts.db_office_id,
                       ts.cwms_ts_id,
                       tt.date_time,
                       tt.version_date,
                       tt.data_entry_date,
                       tt.attribute,
                       null as std_text_id,
                       ts.db_office_code,
                       ts.location_code,
                       tt.ts_code,
                       tt.clob_code
                  from at_tsv_text tt,
                       at_cwms_ts_id ts
                 where ts.ts_code = tt.ts_code
               ) q221
               left outer join
               (select ts_code,
                       date_time,
                       version_date,
                       value,
                       quality_code
                  from av_tsv
               ) q222 on q222.ts_code = q221.ts_code and q222.date_time = q221.date_time and q222.version_date = q221.version_date
               left outer join
               (select clob_code,
                       value as text_value
                  from at_clob
               ) q223 on q223.clob_code = q221.clob_code
       ) q2
       join
       av_cwms_ts_id2 v2 on v2.ts_code = q2.ts_code and v2.ts_alias_group is not null;

begin
	execute immediate 'grant select on av_ts_text to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_text for av_ts_text;

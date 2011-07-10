--
-- AV_LOC  (View)
--
--  Dependencies:
--   AT_LOCATION_KIND (Table)
--   CWMS_NATION (Table)
--   CWMS_OFFICE (Table)
--   CWMS_STATE (Table)
--   CWMS_TIME_ZONE (Table)
--   CWMS_UNIT_CONVERSION (Table)
--   CWMS_COUNTY (Table)
--   AT_BASE_LOCATION (Table)
--   AT_DISPLAY_UNITS (Table)
--   AT_PHYSICAL_LOCATION (Table)
--

CREATE OR REPLACE FORCE VIEW av_loc
(
    location_code,
    base_location_code,
    db_office_id,
    base_location_id,
    sub_location_id,
    location_id,
    location_type,
    unit_system,
    elevation,
    unit_id,
    vertical_datum,
    longitude,
    latitude,
    horizontal_datum,
    time_zone_name,
    county_name,
    state_initial,
    public_name,
    long_name,
    description,
    base_loc_active_flag,
    loc_active_flag,
    location_kind_id,
    map_label,
    published_latitude,
    published_longitude,
    bounding_office_id,
    nation_id,
    nearest_city
)
AS
    SELECT    location_code, base_location_code, db_office_id, base_location_id,
                sub_location_id, location_id, location_type, unit_system,
                (elevation * factor + offset) elevation, to_unit_id unit_id,
                vertical_datum, longitude, latitude, horizontal_datum,
                time_zone_name, county_name, state_initial, public_name,
                long_name, description, base_loc_active_flag, loc_active_flag,
                location_kind_id, map_label, published_latitude,
                published_longitude, bounding_office_id, nation_id, nearest_city
      FROM        (SELECT     c.office_code db_office_code, location_code,
                                 base_location_code, c.office_id db_office_id,
                                 base_location_id, sub_location_id,
                                 base_location_id || SUBSTR ('-', 1, LENGTH (sub_location_id)) || sub_location_id location_id,
                                 location_type, elevation, vertical_datum, longitude,
                                 latitude, horizontal_datum, time_zone_name,
                                 county_name, state_initial, a.public_name,
                                 a.long_name, a.description,
                                 b.active_flag base_loc_active_flag,
                                 a.active_flag loc_active_flag, location_kind_id,
                                 map_label, published_latitude, published_longitude,
                                 d.office_id bounding_office_id, nation_id,
                                 nearest_city
                        FROM         (   (    (     (   (    (     (   at_physical_location a
                                                                      LEFT OUTER JOIN
                                                                          cwms_office d
                                                                      USING (office_code))
                                                                 JOIN
                                                                     at_base_location b
                                                                 USING (base_location_code))
                                                            JOIN
                                                                cwms_office c
                                                            ON b.db_office_code =
                                                                    c.office_code)
                                                      LEFT OUTER JOIN
                                                          at_location_kind
                                                      ON location_kind =
                                                              location_kind_code)
                                                 LEFT OUTER JOIN
                                                     cwms_time_zone
                                                 USING (time_zone_code))
                                            LEFT OUTER JOIN
                                                cwms_county
                                            USING (county_code))
                                      LEFT OUTER JOIN
                                          cwms_state
                                      USING (state_code))
                                 LEFT OUTER JOIN
                                     cwms_nation
                                 USING (nation_code)
                      WHERE     location_code != 0) aa
                NATURAL JOIN
                    (SELECT     adu.db_office_code, adu.unit_system, cuc.to_unit_id,
                                 factor, offset
                        FROM     at_display_units adu, cwms_unit_conversion cuc
                      WHERE          adu.parameter_code = 10
                                 AND adu.display_unit_code = cuc.to_unit_code
                                 AND cuc.from_unit_code = 39) bb
/


--
-- CWMS_V_LOC  (Synonym) 
--
--  Dependencies: 
--   AV_LOC (View)
--
CREATE PUBLIC SYNONYM CWMS_V_LOC FOR AV_LOC
/


GRANT SELECT ON AV_LOC TO CWMS_USER
/

SHOW ERRORS;

-------------------------
-- AV_LOG_MESSAGE view.
-- 
CREATE OR REPLACE FORCE VIEW AV_LOG_MESSAGE
(
   MSG_ID,
   LOG_TIMESTAMP_UTC,
   REPORT_TIMESTAMP_UTC,
   OFFICE_ID,
   COMPONENT,
   INSTANCE,
   HOST,
   PORT,
   MSG_LEVEL,
   MSG_TYPE,
   MSG_TEXT,
   PROPERTIES
)
AS
   SELECT a.msg_id,
          a.log_timestamp_utc,
          a.report_timestamp_utc,
          c.office_id,
          a.component,
          a.instance,
          a.host,
          a.port,
          CASE a.msg_level
             WHEN 0 THEN 'None'
             WHEN 1 THEN 'Normal'
             WHEN 2 THEN 'Normal+'
             WHEN 3 THEN 'Basic'
             WHEN 4 THEN 'Basic+'
             WHEN 5 THEN 'Detailed'
             WHEN 6 THEN 'Detailed+'
             WHEN 7 THEN 'Verbose'
          END
             AS msg_level,
          d.message_type_id AS msg_type,
          a.msg_text,
          cwms_msg.
          parse_log_msg_prop_tab (
             CAST (
                MULTISET (  SELECT b.msg_id,
                                   b.prop_name,
                                   b.prop_type,
                                   b.prop_value,
                                   b.prop_text
                              FROM at_log_message_properties b
                             WHERE b.msg_id = a.msg_id
                          ORDER BY b.prop_name) AS log_message_props_tab_t))
             AS properties
     FROM at_log_message a, cwms_office c, cwms_log_message_types d
    WHERE c.office_code = a.office_code AND d.message_type_code = a.msg_type;
/
SHOW ERRORS;    
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_ts_alias (category_id,
                                     GROUP_ID,
                                     ts_code,
                                     db_office_id,
                                     ts_id,
                                     alias_id
                                    )
AS
   SELECT atc.ts_category_id, 
          atg.ts_group_id, 
          atga.ts_code,
          co.office_id as db_office_id, 
          cwms_ts.get_cwms_ts_id(acts.ts_code, co.office_id) as ts_id, 
          atga.ts_alias_id
     FROM at_cwms_ts_spec acts,
          at_ts_group_assignment atga,
          at_ts_group atg,
          at_ts_category atc,
          at_physical_location pl,
          at_base_location bl,
          cwms_office co
    WHERE pl.location_code = acts.location_code
      and bl.base_location_code = pl.base_location_code
      and co.office_code = bl.db_office_code
      AND atga.ts_code = acts.ts_code
      AND atga.ts_group_code = atg.ts_group_code
      AND atg.ts_category_code = atc.ts_category_code
/
show errors;
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_ts_grp_assgn (category_id,
                                         group_id,
                                         ts_code,
                                         db_office_id,
                                         ts_id,
                                         alias_id,
                                         attribute,
                                         ref_ts_id,
                                         shared_alias_id,
                                         shared_ref_ts_id
                                        )
AS
   SELECT atc.ts_category_id, 
          atg.ts_group_id, 
          atga.ts_code,
          co.office_id as db_office_id,
          cwms_ts.get_cwms_ts_id(acts.ts_code, co.office_id) as ts_id, 
          atga.ts_alias_id,
          atga.ts_attribute,
          cwms_ts.get_cwms_ts_id(acts2.ts_code, co.office_id) as ref_ts_id,
          atg.shared_ts_alias_id,
          cwms_ts.get_cwms_ts_id(acts3.ts_code, co.office_id) as shared_ref_ts_id
     FROM at_cwms_ts_spec acts,
          at_ts_group_assignment atga,
          at_ts_group atg,
          at_ts_category atc,
          at_physical_location pl,
          at_base_location bl,
          cwms_office co,
          at_cwms_ts_spec acts2,
          at_cwms_ts_spec acts3
    WHERE pl.location_code = acts.location_code
      and bl.base_location_code = pl.base_location_code
      and co.office_code = bl.db_office_code
      AND atga.ts_code = acts.ts_code
      AND atga.ts_group_code = atg.ts_group_code
      AND atg.ts_category_code = atc.ts_category_code
      AND acts2.ts_code(+) = atga.ts_ref_code
      AND acts3.ts_code(+) = atg.shared_ts_ref_code
/
show errors;
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_ts_cat_grp (cat_db_office_id,
                                      ts_category_id,
                                      ts_category_desc,
                                      grp_db_office_id,
                                      ts_group_id,
                                      ts_group_desc,
                                      shared_ts_alias_id,
                                      shared_ref_ts_id
                                      )
AS
   SELECT o1.office_id as cat_db_office_id, 
          ts_category_id, 
          ts_category_desc,
          o2.office_id as grp_db_office_id, 
          ts_group_id, 
          ts_group_desc,
          shared_ts_alias_id,
          cwms_ts.get_cwms_ts_id(shared_ts_ref_code, o2.office_id) as shared_ref_ts_id 
     FROM cwms_office o1,
          cwms_office o2,
          at_ts_category attc,
          at_ts_group attg,
          at_cwms_ts_spec atcts
    WHERE attc.db_office_code = o1.office_code
      AND attg.db_office_code = o2.office_code(+)
      AND attc.ts_category_code = attg.ts_category_code(+)
      AND atcts.ts_code(+) = attg.shared_ts_ref_code
/
show errors;
--------------------------------------------------------------------------------
create or replace force view av_loc_lvl_ts_map as
select office_id,
       cwms_ts_id,
       location_level_id,
       level_indicator_id,
       attribute_id,
       attribute_value
  from ( select lvl.office_id,
                lvl.cwms_ts_id,
                lvl.location_level_id,
                ind.level_indicator_id,
                lvl.attribute_id,
                lvl.attribute_value,
                ind.level_indicator_code
           from ( select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         null as attribute_value,
                         null as attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is null
--                     
                   union all
--
                  select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         ll.attribute_value,
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id
                         ||'.'
                         ||pt2.parameter_type_id
                         ||'.'
                         ||d2.duration_id attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         ll.attribute_parameter_code,
                         ll.attribute_parameter_type_code,
                         ll.attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o,
                         at_parameter p2,
                         cwms_base_parameter bp2,
                         cwms_parameter_type pt2,
                         cwms_duration d2
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is not null
                     and p2.parameter_code = ll.attribute_parameter_code and
                         bp2.base_parameter_code = p2.base_parameter_code and
                         pt2.parameter_type_code = ll.attribute_parameter_type_code and
                         d2.duration_code = ll.duration_code
                ) lvl
--                
                join
--                
                ( select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         null as attribute_value,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is null
--                   
                  union all
--                    
                  select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         lli.attr_value as attribute_value,
                         lli.attr_parameter_code as attribute_parameter_code,
                         lli.attr_parameter_type_code as attribute_parameter_type_code,
                         lli.attr_duration_code as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is not null
--                    
                ) ind
                on  ind.location_code = lvl.location_code
                and ind.specified_level_code = lvl.specified_level_code
                and ind.parameter_code = lvl.parameter_code
                and ind.parameter_type_code = lvl.parameter_type_code
                and ind.duration_code = lvl.duration_code
                and nvl((to_char(ind.attribute_value)), '@') = nvl((to_char(lvl.attribute_value)), '@')
                and nvl((to_char(ind.attribute_parameter_code)), '@') = nvl((to_char(lvl.attribute_parameter_code)), '@')
                and nvl((to_char(ind.attribute_parameter_type_code)), '@') = nvl((to_char(lvl.attribute_parameter_type_code)), '@')
                and nvl((to_char(ind.attribute_duration_code)), '@') = nvl((to_char(lvl.attribute_duration_code)), '@')
       )
/
show errors;
--------------------------------------------------------------------------------
create or replace force view av_loc_lvl_cur_max_ind (
   office_id,
   cwms_ts_id,
   level_indicator_id,
   attribute_id,
   attribute_value,
   max_indicator,
   indicator_name
)
as
select q1.office_id,
       q1.cwms_ts_id,
       q1.level_indicator_id,
       q1.attribute_id,
       q1.attribute_value,
       q1.max_indicator,
       case
          when q1.max_indicator = 0 then 'None'
          else cond.name
       end as indicator_name
  from ( select lvl.office_id,
                lvl.cwms_ts_id,
                lvl.location_level_id
                ||'.'
                ||ind.level_indicator_id as level_indicator_id,
                lvl.attribute_id,
                lvl.attribute_value,
                ind.level_indicator_code,
                cwms_display.retrieve_status_indicator_f(
                   p_tsid            => lvl.cwms_ts_id,
                   p_level_id        => lvl.location_level_id,
                   p_indicator_id    => ind.level_indicator_id,
                   p_attribute_id    => lvl.attribute_id,
                   p_attribute_value => lvl.attribute_value,
                   p_attribute_unit  => null,
                   p_office_id       => lvl.office_id) as max_indicator
           from ( select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         null as attribute_value,
                         null as attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is null
--
                   union all
--
                  select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         ll.attribute_value,
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id
                         ||'.'
                         ||pt2.parameter_type_id
                         ||'.'
                         ||d2.duration_id attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         ll.attribute_parameter_code,
                         ll.attribute_parameter_type_code,
                         ll.attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o,
                         at_parameter p2,
                         cwms_base_parameter bp2,
                         cwms_parameter_type pt2,
                         cwms_duration d2
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is not null
                     and p2.parameter_code = ll.attribute_parameter_code and
                         bp2.base_parameter_code = p2.base_parameter_code and
                         pt2.parameter_type_code = ll.attribute_parameter_type_code and
                         d2.duration_code = ll.duration_code
                ) lvl
--
                join
--
                ( select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         null as attribute_value,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is null
--
                  union all
--
                  select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         lli.attr_value as attribute_value,
                         lli.attr_parameter_code as attribute_parameter_code,
                         lli.attr_parameter_type_code as attribute_parameter_type_code,
                         lli.attr_duration_code as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is not null
--
                ) ind
                on  ind.location_code = lvl.location_code
                and ind.specified_level_code = lvl.specified_level_code
                and ind.parameter_code = lvl.parameter_code
                and ind.parameter_type_code = lvl.parameter_type_code
                and ind.duration_code = lvl.duration_code
                and nvl((to_char(ind.attribute_value)), '@') = nvl((to_char(lvl.attribute_value)), '@')
                and nvl((to_char(ind.attribute_parameter_code)), '@') = nvl((to_char(lvl.attribute_parameter_code)), '@')
                and nvl((to_char(ind.attribute_parameter_type_code)), '@') = nvl((to_char(lvl.attribute_parameter_type_code)), '@')
                and nvl((to_char(ind.attribute_duration_code)), '@') = nvl((to_char(lvl.attribute_duration_code)), '@')
       ) q1
--
       join
--
       ( select level_indicator_code,
                level_indicator_value as value,
                description as name
           from at_loc_lvl_indicator_cond
       ) cond
       on cond.level_indicator_code = q1.level_indicator_code
 where q1.max_indicator = 0 
    or cond.value = q1.max_indicator
/
show errors;    
COMMIT;

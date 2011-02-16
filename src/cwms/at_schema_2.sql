/* Formatted on 2006/12/19 11:53 (Formatter Plus v4.8.8) */
-------------------------
-- AV_LOC view.
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
    active_flag,
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
                long_name, description, active_flag, location_kind_id, map_label,
                published_latitude, published_longitude, bounding_office_id,
                nation_id, nearest_city
      FROM        (SELECT     c.office_code db_office_code, location_code,
                                 base_location_code, c.office_id db_office_id,
                                 base_location_id, sub_location_id,
                                     base_location_id
                                 || SUBSTR ('-', 1, LENGTH (sub_location_id))
                                 || sub_location_id
                                     location_id, location_type, elevation,
                                 vertical_datum, longitude, latitude,
                                 horizontal_datum, time_zone_name, county_name,
                                 state_initial, a.public_name, a.long_name,
                                 a.description, a.active_flag, location_kind_id,
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
                                 AND cuc.from_unit_code = 39) bb;
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
                          ORDER BY b.prop_name) AS log_message_properties_tab_t))
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
COMMIT;

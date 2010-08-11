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
COMMIT;

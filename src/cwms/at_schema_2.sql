/* Formatted on 2006/12/19 11:53 (Formatter Plus v4.8.8) */
-------------------------
-- AV_LOC view.
-- 
CREATE OR REPLACE VIEW av_loc (location_code,
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
   SELECT DISTINCT
          apl.location_code, abl.base_location_code,
          co.office_id db_office_id, abl.base_location_id,
          apl.sub_location_id,
             abl.base_location_id
          || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
          || apl.sub_location_id location_id,
          apl.location_type, adu.unit_system,
          TO_NUMBER (apl.elevation * cuc.factor + cuc.offset) elevation,
          cuc.to_unit_id unit_id, apl.vertical_datum, apl.longitude,
          apl.latitude, apl.horizontal_datum, ctz.time_zone_name,
          cc.county_name, cs.state_initial, apl.public_name, apl.long_name,
          apl.description, apl.active_flag,
          alk.location_kind_id location_kind_id,
          apl.map_label, apl.published_latitude,
          apl.published_longitude,
          case when apl.office_code is null
             then
               null
             else
                co2.office_id
          end bounding_office_id,
          case when apl.nation_code is null
             then
               null
             else
                cn.nation_id
          end nation_id,
          apl.nearest_city
     FROM at_physical_location apl,
          at_base_location abl,
          cwms_county cc,
          cwms_office co,
          cwms_state cs,
          cwms_time_zone ctz,
          at_location_kind alk,
          cwms_office co2,
          cwms_nation cn,
          at_display_units adu,
          cwms_unit_conversion cuc
    WHERE (cc.county_code = NVL (apl.county_code, 0))
      AND (cs.state_code = NVL (cc.state_code, 0))
      AND (abl.db_office_code = co.office_code)
      AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
      AND apl.base_location_code = abl.base_location_code
      AND apl.location_code != 0
      AND adu.parameter_code =
                         cwms_ts.get_parameter_code ('Elev', NULL, 'CWMS', 'F')
      AND cuc.from_unit_id = 'm'
      AND cuc.to_unit_code = adu.display_unit_code
      AND alk.location_kind_code = apl.location_kind
      AND (apl.office_code is null or co2.office_code = apl.office_code)
      AND (apl.nation_code is null or cn.nation_code = apl.nation_code)
      AND adu.db_office_code = abl.db_office_code;
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

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL', null,
'
/**
 * Displays information about location levels
 *
 * @since CWMS 2.1
 *
 * @field office_id          Office that owns the location level
 * @field location_level_id  The location level identifier
 * @field attribute_id       The attribute identifier, if any, for the location level
 * @field level_date         The effective data for the location level
 * @field unit_system        The unit system (SI or EN) that units are displayed in
 * @field attribute_unit     The unit of the attribute, if any
 * @field level_unit         The unit of the level
 * @field attribute_value    The value of the attribute, if any
 * @field constant_level     The value of the location level, if it is a constant value
 * @field interval_origin    The beginning of one interval, if the location level is a recurring pattern
 * @field calendar_interval  The length of the interval if expressed in months or years (cannot be used with time_interval)
 * @field time_interval      The length of the interval if expressed in days or less (cannot be used with calendar_interval)
 * @field interpolate        Flag <code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether to interpolate between pattern breakpoints
 * @field calendar_offset    Years and months into the interval for the seasonal level (combined with time_offset)
 * @field time_offset        Days, hours, and minutes into the interval for the seasonal level (combined with calendar_offset)
 * @field seasonal_level     The level value at the offset into the interval specified by calendar_offset and time_offset
 * @field tsid               The time series identifier for the level, if it is specified as a time series
 * @field level_comment      Comment about the location level
 * @field attribute_comment  Comment about the attribute, if any
 * @field base_location_id   The base location portion of the location level
 * @field sub_location_id    The sub-location portion of the location level
 * @field location_id        The full location portion of the location level
 * @field base_parameter_id  The base parameter portion of the location level
 * @field sub_parameter_id   The sub-parameter portion of the location level
 * @field parameter_id       The full parameter portion of the location level
 * @field duration_id        The duration portion of the location level
 * @field specified_level_id The specified level portion of the location level
 */
');

CREATE OR REPLACE FORCE VIEW av_location_level
AS
    SELECT      office_id,
                  location_id || '.' || parameter_id || '.' || parameter_type_id || '.' || duration_id || '.' || specified_level_id AS location_level_id,
                  attribute_parameter_id || SUBSTR ('.', 1, LENGTH (attribute_parameter_type_id)) || attribute_parameter_type_id || SUBSTR ('.', 1, LENGTH (attribute_duration_id)) || attribute_duration_id AS attribute_id,
                  level_date, unit_system, attribute_unit, level_unit,
                  attribute_value, constant_level, interval_origin,
                  SUBSTR (calendar_interval_, 2) AS calendar_interval,
                  time_interval, interpolate,
                  SUBSTR (calendar_offset_, 2) AS calendar_offset,
                  SUBSTR (time_offset_, 2) AS time_offset,
                  seasonal_level,
                  tsid,
                  level_comment,
                  attribute_comment,
                  cwms_util.get_base_id(location_id) as base_location_id,
                  cwms_util.get_sub_id(location_id) as sub_location_id,
                  location_id,
                  cwms_util.get_base_id(parameter_id) as base_parameter_id,
                  cwms_util.get_sub_id(parameter_id) as sub_parameter_id,
                  parameter_id,
                  duration_id,
                  specified_level_id
         FROM   ( (SELECT   c_o.office_id AS office_id,
                            a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                            c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                            c_pt1.parameter_type_id AS parameter_type_id,
                            c_d1.duration_id AS duration_id,
                            a_sl.specified_level_id AS specified_level_id,
                            NULL AS attribute_parameter_id,
                            NULL AS attribute_parameter_type_id,
                            NULL AS attribute_duration_id,
                            a_ll.location_level_date AS level_date,
                            us.unit_system AS unit_system,
                            c_uc1.to_unit_id AS level_unit,
                            NULL AS attribute_unit,
                            a_ll.attribute_value AS attribute_value,
                            a_ll.location_level_value * c_uc1.factor + c_uc1.offset AS constant_level,
                            a_ll.interval_origin AS interval_origin,
                            a_ll.calendar_interval AS calendar_interval_,
                            a_ll.time_interval AS time_interval,
                            a_ll.interpolate AS interpolate,
                            NULL AS calendar_offset_, NULL AS time_offset_,
                            NULL AS seasonal_level,
                            NULL AS tsid,
                            a_ll.location_level_comment AS level_comment,
                            a_ll.attribute_comment AS attribute_comment
                     FROM   at_location_level a_ll,
                            at_specified_level a_sl,
                            at_physical_location a_pl,
                            at_base_location a_bl,
                            at_parameter a_p1,
                            cwms_duration c_d1,
                            cwms_base_parameter c_bp1,
                            cwms_parameter_type c_pt1,
                            cwms_unit_conversion c_uc1,
                            cwms_office c_o,
                            (SELECT    'EN' AS unit_system
                                FROM    DUAL
                              UNION ALL
                              SELECT    'SI' AS unit_system
                                FROM    DUAL) us
                  WHERE         a_pl.location_code = a_ll.location_code
                            AND a_bl.base_location_code = a_pl.base_location_code
                            AND c_o.office_code = a_bl.db_office_code
                            AND a_p1.parameter_code = a_ll.parameter_code
                            AND c_bp1.base_parameter_code =
                                      a_p1.base_parameter_code
                            AND c_pt1.parameter_type_code =
                                      a_ll.parameter_type_code
                            AND c_d1.duration_code = a_ll.duration_code
                            AND a_sl.specified_level_code =
                                      a_ll.specified_level_code
                            AND c_uc1.from_unit_code = c_bp1.unit_code
                            AND c_uc1.to_unit_code =
                                      DECODE (us.unit_system,
                                                'EN', c_bp1.display_unit_code_en,
                                                'SI', c_bp1.display_unit_code_si
                                               )
                            AND a_ll.attribute_parameter_code IS NULL
                            AND a_ll.location_level_value IS NOT NULL
                            AND a_ll.ts_code IS NULL)
                    UNION ALL
                    (SELECT     c_o.office_id AS office_id,
                                 a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                                 c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                                 c_pt1.parameter_type_id AS parameter_type_id,
                                 c_d1.duration_id AS duration_id,
                                 a_sl.specified_level_id AS specified_level_id,
                                 NULL AS attribute_parameter_id,
                                 NULL AS attribute_parameter_type_id,
                                 NULL AS attribute_duration_id,
                                 a_ll.location_level_date AS level_date,
                                 us.unit_system AS unit_system,
                                 c_uc1.to_unit_id AS level_unit, NULL AS attribute_unit,
                                 a_ll.attribute_value AS attribute_value,
                                 NULL AS constant_level,
                                 a_ll.interval_origin AS interval_origin,
                                 a_ll.calendar_interval AS calendar_interval_,
                                 a_ll.time_interval AS time_interval,
                                 a_ll.interpolate AS interpolate,
                                 a_sll.calendar_offset AS calendar_offset_,
                                 a_sll.time_offset AS time_offset_,
                                 a_sll.VALUE * c_uc1.factor + c_uc1.offset AS seasonal_level,
                                 NULL AS tsid,
                                 a_ll.location_level_comment AS level_comment,
                                 a_ll.attribute_comment AS attribute_comment
                        FROM     at_location_level a_ll,
                                 at_seasonal_location_level a_sll,
                                 at_specified_level a_sl,
                                 at_physical_location a_pl,
                                 at_base_location a_bl,
                                 at_parameter a_p1,
                                 cwms_duration c_d1,
                                 cwms_base_parameter c_bp1,
                                 cwms_parameter_type c_pt1,
                                 cwms_unit_conversion c_uc1,
                                 cwms_office c_o,
                                 (SELECT   'EN' AS unit_system
                                     FROM   DUAL
                                  UNION ALL
                                  SELECT   'SI' AS unit_system
                                     FROM   DUAL) us
                      WHERE          a_pl.location_code = a_ll.location_code
                                 AND a_bl.base_location_code = a_pl.base_location_code
                                 AND c_o.office_code = a_bl.db_office_code
                                 AND a_p1.parameter_code = a_ll.parameter_code
                                 AND c_bp1.base_parameter_code =
                                          a_p1.base_parameter_code
                                 AND c_pt1.parameter_type_code =
                                          a_ll.parameter_type_code
                                 AND c_d1.duration_code = a_ll.duration_code
                                 AND a_sl.specified_level_code =
                                          a_ll.specified_level_code
                                 AND c_uc1.from_unit_code = c_bp1.unit_code
                                 AND c_uc1.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp1.display_unit_code_en,
                                                     'SI', c_bp1.display_unit_code_si
                                                    )
                                 AND a_ll.attribute_parameter_code IS NULL
                                 AND a_ll.location_level_value IS NULL
                                 AND a_ll.ts_code IS NULL
                                 AND a_sll.location_level_code =
                                          a_ll.location_level_code)
                    UNION ALL
                    (SELECT     c_o.office_id AS office_id,
                                 a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                                 c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                                 c_pt1.parameter_type_id AS parameter_type_id,
                                 c_d1.duration_id AS duration_id,
                                 a_sl.specified_level_id AS specified_level_id,
                                 c_bp2.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id AS attribute_parameter_id,
                                 c_pt2.parameter_type_id AS attribute_parameter_type_id,
                                 c_d2.duration_id AS attribute_duration_id,
                                 a_ll.location_level_date AS level_date,
                                 us.unit_system AS unit_system,
                                 c_uc1.to_unit_id AS level_unit,
                                 c_uc2.to_unit_id AS attribute_unit,
                                 a_ll.attribute_value * c_uc2.factor + c_uc2.offset AS attribute_value,
                                 a_ll.location_level_value * c_uc1.factor + c_uc1.offset AS constant_level,
                                 a_ll.interval_origin AS interval_origin,
                                 a_ll.calendar_interval AS calendar_interval_,
                                 a_ll.time_interval AS time_interval,
                                 a_ll.interpolate AS interpolate,
                                 NULL AS calendar_offset_, NULL AS time_offset_,
                                 NULL AS seasonal_level,
                                 NULL AS tsid,
                                 a_ll.location_level_comment AS level_comment,
                                 a_ll.attribute_comment AS attribute_comment
                        FROM     at_location_level a_ll,
                                 at_specified_level a_sl,
                                 at_physical_location a_pl,
                                 at_base_location a_bl,
                                 at_parameter a_p1,
                                 at_parameter a_p2,
                                 cwms_duration c_d1,
                                 cwms_base_parameter c_bp1,
                                 cwms_parameter_type c_pt1,
                                 cwms_unit_conversion c_uc1,
                                 cwms_duration c_d2,
                                 cwms_base_parameter c_bp2,
                                 cwms_parameter_type c_pt2,
                                 cwms_unit_conversion c_uc2,
                                 cwms_office c_o,
                                 (SELECT   'EN' AS unit_system
                                     FROM   DUAL
                                  UNION ALL
                                  SELECT   'SI' AS unit_system
                                     FROM   DUAL) us
                      WHERE          a_pl.location_code = a_ll.location_code
                                 AND a_bl.base_location_code = a_pl.base_location_code
                                 AND c_o.office_code = a_bl.db_office_code
                                 AND a_p1.parameter_code = a_ll.parameter_code
                                 AND c_bp1.base_parameter_code =
                                          a_p1.base_parameter_code
                                 AND c_pt1.parameter_type_code =
                                          a_ll.parameter_type_code
                                 AND c_d1.duration_code = a_ll.duration_code
                                 AND a_sl.specified_level_code =
                                          a_ll.specified_level_code
                                 AND c_uc1.from_unit_code = c_bp1.unit_code
                                 AND c_uc1.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp1.display_unit_code_en,
                                                     'SI', c_bp1.display_unit_code_si
                                                    )
                                 AND a_ll.attribute_parameter_code IS NOT NULL
                                 AND a_p2.parameter_code =
                                          a_ll.attribute_parameter_code
                                 AND c_bp2.base_parameter_code =
                                          a_p2.base_parameter_code
                                 AND c_pt2.parameter_type_code =
                                          a_ll.attribute_parameter_type_code
                                 AND c_d2.duration_code = a_ll.attribute_duration_code
                                 AND c_uc2.from_unit_code = c_bp2.unit_code
                                 AND c_uc2.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp2.display_unit_code_en,
                                                     'SI', c_bp2.display_unit_code_si
                                                    )
                                 AND a_ll.location_level_value IS NOT NULL
                                 AND a_ll.ts_code IS NULL)
                    UNION ALL
                    (SELECT     c_o.office_id AS office_id,
                                 a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                                 c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                                 c_pt1.parameter_type_id AS parameter_type_id,
                                 c_d1.duration_id AS duration_id,
                                 a_sl.specified_level_id AS specified_level_id,
                                 c_bp2.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id AS attribute_parameter_id,
                                 c_pt2.parameter_type_id AS attribute_parameter_type_id,
                                 c_d2.duration_id AS attribute_duration_id,
                                 a_ll.location_level_date AS level_date,
                                 us.unit_system AS unit_system,
                                 c_uc1.to_unit_id AS level_unit,
                                 c_uc2.to_unit_id AS attribute_unit,
                                 a_ll.attribute_value * c_uc2.factor + c_uc2.offset AS attribute_value,
                                 NULL AS constant_level,
                                 a_ll.interval_origin AS interval_origin,
                                 a_ll.calendar_interval AS calendar_interval_,
                                 a_ll.time_interval AS time_interval,
                                 a_ll.interpolate AS interpolate,
                                 a_sll.calendar_offset AS calendar_offset_,
                                 a_sll.time_offset AS time_offset_,
                                 a_sll.VALUE * c_uc1.factor + c_uc1.offset AS seasonal_level,
                                 NULL AS tsid,
                                 a_ll.location_level_comment AS level_comment,
                                 a_ll.attribute_comment AS attribute_comment
                        FROM     at_location_level a_ll,
                                 at_seasonal_location_level a_sll,
                                 at_specified_level a_sl,
                                 at_physical_location a_pl,
                                 at_base_location a_bl,
                                 at_parameter a_p1,
                                 at_parameter a_p2,
                                 cwms_duration c_d1,
                                 cwms_base_parameter c_bp1,
                                 cwms_parameter_type c_pt1,
                                 cwms_unit_conversion c_uc1,
                                 cwms_duration c_d2,
                                 cwms_base_parameter c_bp2,
                                 cwms_parameter_type c_pt2,
                                 cwms_unit_conversion c_uc2,
                                 cwms_office c_o,
                                 (SELECT   'EN' AS unit_system
                                     FROM   DUAL
                                  UNION ALL
                                  SELECT   'SI' AS unit_system
                                     FROM   DUAL) us
                      WHERE          a_pl.location_code = a_ll.location_code
                                 AND a_bl.base_location_code = a_pl.base_location_code
                                 AND c_o.office_code = a_bl.db_office_code
                                 AND a_p1.parameter_code = a_ll.parameter_code
                                 AND c_bp1.base_parameter_code =
                                          a_p1.base_parameter_code
                                 AND c_pt1.parameter_type_code =
                                          a_ll.parameter_type_code
                                 AND c_d1.duration_code = a_ll.duration_code
                                 AND a_sl.specified_level_code =
                                          a_ll.specified_level_code
                                 AND c_uc1.from_unit_code = c_bp1.unit_code
                                 AND c_uc1.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp1.display_unit_code_en,
                                                     'SI', c_bp1.display_unit_code_si
                                                    )
                                 AND a_ll.attribute_parameter_code IS NOT NULL
                                 AND a_p2.parameter_code =
                                          a_ll.attribute_parameter_code
                                 AND c_bp2.base_parameter_code =
                                          a_p2.base_parameter_code
                                 AND c_pt2.parameter_type_code =
                                          a_ll.attribute_parameter_type_code
                                 AND c_d2.duration_code = a_ll.attribute_duration_code
                                 AND c_uc2.from_unit_code = c_bp2.unit_code
                                 AND c_uc2.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp2.display_unit_code_en,
                                                     'SI', c_bp2.display_unit_code_si
                                                    )
                                 AND a_ll.location_level_value IS NULL
                                 AND a_ll.ts_code IS NULL
                                 AND a_sll.location_level_code =
                                          a_ll.location_level_code)
                    UNION ALL
                    (SELECT c_o.office_id AS office_id,
                            a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                            c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                            c_pt1.parameter_type_id AS parameter_type_id,
                            c_d1.duration_id AS duration_id,
                            a_sl.specified_level_id AS specified_level_id,
                            NULL AS attribute_parameter_id,
                            NULL AS attribute_parameter_type_id,
                            NULL AS attribute_duration_id,
                            a_ll.location_level_date AS level_date,
                            NULL AS unit_system,
                            NULL AS level_unit,
                            NULL AS attribute_unit,
                            a_ll.attribute_value AS attribute_value,
                            NULL AS constant_level,
                            a_ll.interval_origin AS interval_origin,
                            a_ll.calendar_interval AS calendar_interval_,
                            a_ll.time_interval AS time_interval,
                            a_ll.interpolate AS interpolate,
                            NULL AS calendar_offset_, NULL AS time_offset_,
                            NULL AS seasonal_level,
                            cwms_ts.get_ts_id(a_ll.ts_code) AS tsid,
                            a_ll.location_level_comment AS level_comment,
                            a_ll.attribute_comment AS attribute_comment
                     FROM   at_location_level a_ll,
                            at_specified_level a_sl,
                            at_physical_location a_pl,
                            at_base_location a_bl,
                            at_parameter a_p1,
                            cwms_duration c_d1,
                            cwms_base_parameter c_bp1,
                            cwms_parameter_type c_pt1,
                            cwms_unit_conversion c_uc1,
                            cwms_office c_o
                  WHERE         a_pl.location_code = a_ll.location_code
                            AND a_bl.base_location_code = a_pl.base_location_code
                            AND c_o.office_code = a_bl.db_office_code
                            AND a_p1.parameter_code = a_ll.parameter_code
                            AND c_bp1.base_parameter_code =
                                      a_p1.base_parameter_code
                            AND c_pt1.parameter_type_code =
                                      a_ll.parameter_type_code
                            AND c_d1.duration_code = a_ll.duration_code
                            AND a_sl.specified_level_code =
                                      a_ll.specified_level_code
                            AND a_ll.attribute_parameter_code IS NULL
                            AND a_ll.location_level_value IS NULL
                            AND a_ll.ts_code IS NOT NULL)
                    UNION ALL
                    (SELECT     c_o.office_id AS office_id,
                                 a_bl.base_location_id || SUBSTR ('-', 1, LENGTH (a_pl.sub_location_id)) || a_pl.sub_location_id AS location_id,
                                 c_bp1.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id AS parameter_id,
                                 c_pt1.parameter_type_id AS parameter_type_id,
                                 c_d1.duration_id AS duration_id,
                                 a_sl.specified_level_id AS specified_level_id,
                                 c_bp2.base_parameter_id || SUBSTR ('-', 1, LENGTH (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id AS attribute_parameter_id,
                                 c_pt2.parameter_type_id AS attribute_parameter_type_id,
                                 c_d2.duration_id AS attribute_duration_id,
                                 a_ll.location_level_date AS level_date,
                                 us.unit_system AS unit_system,
                                 c_uc1.to_unit_id AS level_unit,
                                 c_uc2.to_unit_id AS attribute_unit,
                                 a_ll.attribute_value * c_uc2.factor + c_uc2.offset AS attribute_value,
                                 NULL AS constant_level,
                                 a_ll.interval_origin AS interval_origin,
                                 a_ll.calendar_interval AS calendar_interval_,
                                 a_ll.time_interval AS time_interval,
                                 a_ll.interpolate AS interpolate,
                                 NULL AS calendar_offset_,
                                 NULL AS time_offset_,
                                 NULL AS seasonal_level,
                                 cwms_ts.get_ts_id(a_ll.ts_code) AS tsid,
                                 a_ll.location_level_comment AS level_comment,
                                 a_ll.attribute_comment AS attribute_comment
                        FROM     at_location_level a_ll,
                                 at_specified_level a_sl,
                                 at_physical_location a_pl,
                                 at_base_location a_bl,
                                 at_parameter a_p1,
                                 at_parameter a_p2,
                                 cwms_duration c_d1,
                                 cwms_base_parameter c_bp1,
                                 cwms_parameter_type c_pt1,
                                 cwms_unit_conversion c_uc1,
                                 cwms_duration c_d2,
                                 cwms_base_parameter c_bp2,
                                 cwms_parameter_type c_pt2,
                                 cwms_unit_conversion c_uc2,
                                 cwms_office c_o,
                                 (SELECT   'EN' AS unit_system
                                     FROM   DUAL
                                  UNION ALL
                                  SELECT   'SI' AS unit_system
                                     FROM   DUAL) us
                      WHERE          a_pl.location_code = a_ll.location_code
                                 AND a_bl.base_location_code = a_pl.base_location_code
                                 AND c_o.office_code = a_bl.db_office_code
                                 AND a_p1.parameter_code = a_ll.parameter_code
                                 AND c_bp1.base_parameter_code =
                                          a_p1.base_parameter_code
                                 AND c_pt1.parameter_type_code =
                                          a_ll.parameter_type_code
                                 AND c_d1.duration_code = a_ll.duration_code
                                 AND a_sl.specified_level_code =
                                          a_ll.specified_level_code
                                 AND c_uc1.from_unit_code = c_bp1.unit_code
                                 AND c_uc1.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp1.display_unit_code_en,
                                                     'SI', c_bp1.display_unit_code_si
                                                    )
                                 AND a_ll.attribute_parameter_code IS NOT NULL
                                 AND a_p2.parameter_code =
                                          a_ll.attribute_parameter_code
                                 AND c_bp2.base_parameter_code =
                                          a_p2.base_parameter_code
                                 AND c_pt2.parameter_type_code =
                                          a_ll.attribute_parameter_type_code
                                 AND c_d2.duration_code = a_ll.attribute_duration_code
                                 AND c_uc2.from_unit_code = c_bp2.unit_code
                                 AND c_uc2.to_unit_code =
                                          DECODE (us.unit_system,
                                                     'EN', c_bp2.display_unit_code_en,
                                                     'SI', c_bp2.display_unit_code_si
                                                    )
                                 AND a_ll.location_level_value IS NULL
                                 AND a_ll.ts_code IS NOT NULL))
    ORDER BY   office_id,
                  location_level_id,
                  attribute_id,
                  level_date,
                  unit_system,
                  attribute_value,
                  interval_origin + calendar_offset_ + time_offset_;

/
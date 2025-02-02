-----------------------------
-- AV_RATING_VALUES_NATIVE --
-----------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_VALUES_NATIVE', null,
'
/**
 * Displays rating values in native rating units
 *
 * @since CWMS 2.1
 *
 * @see view av_rating
 * @see view av_rating_local
 * @see view av_rating_values
 *
 * @field rating_code Unique numeric code identifying rating
 * @field ind_value_1 The value for the first independent parameter in native rating unit
 * @field ind_value_2 The value for the second independent parameter, if any, in native rating unit
 * @field ind_value_3 The value for the third independent parameter, if any, in native rating unit
 * @field ind_value_4 The value for the fourth independent parameter, if any, in native rating unit
 * @field ind_value_5 The value for the fifth independent parameter, if any, in native rating unit
 * @field dep_value   The value for the dependent parameter in native rating unit
 */
');

CREATE OR REPLACE FORCE VIEW av_rating_values_native
(
    rating_code,
    ind_value_1,
    ind_value_2,
    ind_value_3,
    ind_value_4,
    ind_value_5,
    dep_value
)
AS
    SELECT    DISTINCT r1.rating_code, r1.native_ind_value AS ind_value_1,
                            r2.native_ind_value AS ind_value_2,
                            r3.native_ind_value AS ind_value_3,
                            r4.native_ind_value AS ind_value_4,
                            r5.native_ind_value AS ind_value_5,
                            COALESCE (r1.native_dep_value, r2.native_dep_value, r3.native_dep_value, r4.native_dep_value, r5.native_dep_value) AS dep_value
      FROM    (SELECT     rip.rating_code, rip.rating_ind_param_code,
                             rv.other_ind_hash, rv.ind_value, rv.dep_value,
                             cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') AS native_ind_value,
                             cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') AS native_dep_value,
                             rv.dep_rating_ind_param_code
                    FROM     at_parameter p1,
                             cwms_base_parameter bp1,
                             cwms_unit_conversion uc1,
                             at_parameter p2,
                             cwms_base_parameter bp2,
                             cwms_unit_conversion uc2,
                             at_rating_ind_parameter rip,
                             at_rating_ind_param_spec rips,
                             at_rating_value rv,
                             at_rating r,
                             at_rating_spec rs,
                             at_rating_template rt
                  WHERE          rips.ind_param_spec_code = rip.ind_param_spec_code
                             AND rips.parameter_position = 1
                             AND p1.parameter_code = rips.parameter_code
                             AND bp1.base_parameter_code = p1.base_parameter_code
                             AND rv.rating_ind_param_code =
                                      rip.rating_ind_param_code
                             AND r.rating_code = rip.rating_code
                             AND uc1.from_unit_code = bp1.unit_code
                             AND uc1.to_unit_id =
                                      SUBSTR (
                                          r.native_units,
                                          1,
                                          INSTR (REPLACE (r.native_units, ';', ','),
                                                    ','
                                                  )
                                          - 1
                                      )
                             AND rs.rating_spec_code = r.rating_spec_code
                             AND rt.template_code = rs.template_code
                             AND p2.parameter_code = rt.dep_parameter_code
                             AND bp2.base_parameter_code = p2.base_parameter_code
                             AND uc2.from_unit_code = bp2.unit_code
                             AND uc2.to_unit_id =
                                      SUBSTR (r.native_units,
                                                 INSTR (r.native_units, ';') + 1
                                                )) r1
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') AS native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') AS native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_parameter p1,
                                                  cwms_base_parameter bp1,
                                                  cwms_unit_conversion uc1,
                                                  at_parameter p2,
                                                  cwms_base_parameter bp2,
                                                  cwms_unit_conversion uc2,
                                                  at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv,
                                                  at_rating r,
                                                  at_rating_spec rs,
                                                  at_rating_template rt
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 2
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  AND p1.parameter_code =
                                                            rips.parameter_code
                                                  AND bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  AND r.rating_code = rip.rating_code
                                                  AND uc1.from_unit_code = bp1.unit_code
                                                  AND uc1.to_unit_id =
                                                            CASE INSTR (
                                                                      REPLACE (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      2
                                                                  )
                                                                WHEN 0
                                                                THEN
                                                                    NULL
                                                                ELSE
                                                                    SUBSTR (
                                                                        r.native_units,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            1
                                                                        )
                                                                        + 1,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            2
                                                                        )
                                                                        - INSTR (
                                                                              REPLACE (
                                                                                  r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                              ),
                                                                              ',',
                                                                              1,
                                                                              1
                                                                          )
                                                                        - 1
                                                                    )
                                                            END
                                                  AND rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  AND rt.template_code = rs.template_code
                                                  AND p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  AND bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  AND uc2.from_unit_code = bp2.unit_code
                                                  AND uc2.to_unit_id =
                                                            SUBSTR (
                                                                r.native_units,
                                                                INSTR (r.native_units, ';')
                                                                + 1
                                                            )) r2
                    ON r2.rating_ind_param_code = r1.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') AS native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') AS native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_parameter p1,
                                                  cwms_base_parameter bp1,
                                                  cwms_unit_conversion uc1,
                                                  at_parameter p2,
                                                  cwms_base_parameter bp2,
                                                  cwms_unit_conversion uc2,
                                                  at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv,
                                                  at_rating r,
                                                  at_rating_spec rs,
                                                  at_rating_template rt
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 3
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  AND p1.parameter_code =
                                                            rips.parameter_code
                                                  AND bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  AND r.rating_code = rip.rating_code
                                                  AND uc1.from_unit_code = bp1.unit_code
                                                  AND uc1.to_unit_id =
                                                            CASE INSTR (
                                                                      REPLACE (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      3
                                                                  )
                                                                WHEN 0
                                                                THEN
                                                                    NULL
                                                                ELSE
                                                                    SUBSTR (
                                                                        r.native_units,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            2
                                                                        )
                                                                        + 1,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            3
                                                                        )
                                                                        - INSTR (
                                                                              REPLACE (
                                                                                  r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                              ),
                                                                              ',',
                                                                              1,
                                                                              2
                                                                          )
                                                                        - 1
                                                                    )
                                                            END
                                                  AND rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  AND rt.template_code = rs.template_code
                                                  AND p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  AND bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  AND uc2.from_unit_code = bp2.unit_code
                                                  AND uc2.to_unit_id =
                                                            SUBSTR (
                                                                r.native_units,
                                                                INSTR (r.native_units, ';')
                                                                + 1
                                                            )) r3
                    ON r3.rating_ind_param_code = r2.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') AS native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') AS native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_parameter p1,
                                                  cwms_base_parameter bp1,
                                                  cwms_unit_conversion uc1,
                                                  at_parameter p2,
                                                  cwms_base_parameter bp2,
                                                  cwms_unit_conversion uc2,
                                                  at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv,
                                                  at_rating r,
                                                  at_rating_spec rs,
                                                  at_rating_template rt
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 4
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  AND p1.parameter_code =
                                                            rips.parameter_code
                                                  AND bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  AND r.rating_code = rip.rating_code
                                                  AND uc1.from_unit_code = bp1.unit_code
                                                  AND uc1.to_unit_id =
                                                            CASE INSTR (
                                                                      REPLACE (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      4
                                                                  )
                                                                WHEN 0
                                                                THEN
                                                                    NULL
                                                                ELSE
                                                                    SUBSTR (
                                                                        r.native_units,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            3
                                                                        )
                                                                        + 1,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            4
                                                                        )
                                                                        - INSTR (
                                                                              REPLACE (
                                                                                  r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                              ),
                                                                              ',',
                                                                              1,
                                                                              3
                                                                          )
                                                                        - 1
                                                                    )
                                                            END
                                                  AND rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  AND rt.template_code = rs.template_code
                                                  AND p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  AND bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  AND uc2.from_unit_code = bp2.unit_code
                                                  AND uc2.to_unit_id =
                                                            SUBSTR (
                                                                r.native_units,
                                                                INSTR (r.native_units, ';')
                                                                + 1
                                                            )) r4
                    ON r4.rating_ind_param_code = r3.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') AS native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') AS native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_parameter p1,
                                                  cwms_base_parameter bp1,
                                                  cwms_unit_conversion uc1,
                                                  at_parameter p2,
                                                  cwms_base_parameter bp2,
                                                  cwms_unit_conversion uc2,
                                                  at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv,
                                                  at_rating r,
                                                  at_rating_spec rs,
                                                  at_rating_template rt
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 5
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  AND p1.parameter_code =
                                                            rips.parameter_code
                                                  AND bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  AND r.rating_code = rip.rating_code
                                                  AND uc1.from_unit_code = bp1.unit_code
                                                  AND uc1.to_unit_id =
                                                            CASE INSTR (
                                                                      REPLACE (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      5
                                                                  )
                                                                WHEN 0
                                                                THEN
                                                                    NULL
                                                                ELSE
                                                                    SUBSTR (
                                                                        r.native_units,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            4
                                                                        )
                                                                        + 1,
                                                                        INSTR (
                                                                            REPLACE (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            5
                                                                        )
                                                                        - INSTR (
                                                                              REPLACE (
                                                                                  r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                              ),
                                                                              ',',
                                                                              1,
                                                                              4
                                                                          )
                                                                        - 1
                                                                    )
                                                            END
                                                  AND rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  AND rt.template_code = rs.template_code
                                                  AND p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  AND bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  AND uc2.from_unit_code = bp2.unit_code
                                                  AND uc2.to_unit_id =
                                                            SUBSTR (
                                                                r.native_units,
                                                                INSTR (r.native_units, ';')
                                                                + 1
                                                            )) r5
                    ON r5.rating_ind_param_code = r4.dep_rating_ind_param_code
     WHERE    (r1.dep_value IS NULL
                 OR r1.other_ind_hash = rating_value_t.hash_other_ind (NULL))
                AND (r2.dep_value IS NULL
                      OR r2.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value)
                              ))
                AND (r3.dep_value IS NULL
                      OR r3.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value, r2.ind_value)
                              ))
                AND (r4.dep_value IS NULL
                      OR r4.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value,
                                                     r2.ind_value,
                                                     r3.ind_value
                                                    )
                              ))
                AND (r5.dep_value IS NULL
                      OR r5.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value,
                                                     r2.ind_value,
                                                     r3.ind_value,
                                                     r4.ind_value
                                                    )
                              ));

/
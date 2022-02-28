/**
 * Displays rating values in database storage units
 *
 * @since CWMS 2.1
 *
 * @see view av_rating
 * @see view av_rating_local
 * @see view av_rating_values_native
 *
 * @field rating_code Unique numeric code identifying rating
 * @field ind_value_1 The value for the first independent parameter in database storage unit
 * @field ind_value_2 The value for the second independent parameter, if any, in database storage unit
 * @field ind_value_3 The value for the third independent parameter, if any, in database storage unit
 * @field ind_value_4 The value for the fourth independent parameter, if any, in database storage unit
 * @field ind_value_5 The value for the fifth independent parameter, if any, in database storage unit
 * @field dep_value   The value for the dependent parameter in database storage unit
 */
CREATE OR REPLACE FORCE VIEW av_rating_values
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
    SELECT    DISTINCT p1.rating_code, p1.ind_value AS ind_value_1,
                            p2.ind_value AS ind_value_2, p3.ind_value AS ind_value_3,
                            p4.ind_value AS ind_value_4, p5.ind_value AS ind_value_5,
                            COALESCE (p1.dep_value, p2.dep_value, p3.dep_value, p4.dep_value, p5.dep_value) AS dep_value
      FROM    (SELECT     rip.rating_code, rip.rating_ind_param_code,
                             rv.other_ind_hash, rv.ind_value, rv.dep_value,
                             rv.dep_rating_ind_param_code
                    FROM     at_rating_ind_parameter rip,
                             at_rating_ind_param_spec rips,
                             at_rating_value rv
                  WHERE     rips.ind_param_spec_code = rip.ind_param_spec_code
                             AND rips.parameter_position = 1
                             AND rv.rating_ind_param_code =
                                      rip.rating_ind_param_code) p1
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 2
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code) p2
                    ON p2.rating_ind_param_code = p1.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 3
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code) p3
                    ON p3.rating_ind_param_code = p2.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 4
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code) p4
                    ON p4.rating_ind_param_code = p3.dep_rating_ind_param_code
                LEFT OUTER JOIN (SELECT   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  rv.dep_rating_ind_param_code
                                         FROM   at_rating_ind_parameter rip,
                                                  at_rating_ind_param_spec rips,
                                                  at_rating_value rv
                                        WHERE   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  AND rips.parameter_position = 5
                                                  AND rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code) p5
                    ON p5.rating_ind_param_code = p4.dep_rating_ind_param_code
     WHERE    (p1.dep_value IS NULL
                 OR p1.other_ind_hash = rating_value_t.hash_other_ind (NULL))
                AND (p2.dep_value IS NULL
                      OR p2.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (p1.ind_value)
                              ))
                AND (p3.dep_value IS NULL
                      OR p3.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (p1.ind_value, p2.ind_value)
                              ))
                AND (p4.dep_value IS NULL
                      OR p4.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (p1.ind_value,
                                                     p2.ind_value,
                                                     p3.ind_value
                                                    )
                              ))
                AND (p5.dep_value IS NULL
                      OR p5.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (p1.ind_value,
                                                     p2.ind_value,
                                                     p3.ind_value,
                                                     p4.ind_value
                                                    )
                              ));

/
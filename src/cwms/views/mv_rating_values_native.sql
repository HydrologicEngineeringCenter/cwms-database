-----------------------------
-- AV_RATING_VALUES_NATIVE --
-----------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_RATING_VALUES_NATIVE', null,
'
/**
 * Displays rating values in native rating units
 *
 * @since CWMS 2.1
 *
 * @see view av_rating
 * @see view av_rating_local
 * @see view mv_rating_values
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

create materialized view mv_rating_values_native
(
    rating_code,
    ind_value_1,
    ind_value_2,
    ind_value_3,
    ind_value_4,
    ind_value_5,
    dep_value
)
as
    select    distinct r1.rating_code, r1.native_ind_value as ind_value_1,
                            r2.native_ind_value as ind_value_2,
                            r3.native_ind_value as ind_value_3,
                            r4.native_ind_value as ind_value_4,
                            r5.native_ind_value as ind_value_5,
                            coalesce (r1.native_dep_value, r2.native_dep_value, r3.native_dep_value, r4.native_dep_value, r5.native_dep_value) as dep_value
      from    (select     rip.rating_code, rip.rating_ind_param_code,
                             rv.other_ind_hash, rv.ind_value, rv.dep_value,
                             cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') as native_ind_value,
                             cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') as native_dep_value,
                             rv.dep_rating_ind_param_code
                    from     at_parameter p1,
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
                  where          rips.ind_param_spec_code = rip.ind_param_spec_code
                             and rips.parameter_position = 1
                             and p1.parameter_code = rips.parameter_code
                             and bp1.base_parameter_code = p1.base_parameter_code
                             and rv.rating_ind_param_code =
                                      rip.rating_ind_param_code
                             and r.rating_code = rip.rating_code
                             and uc1.from_unit_code = bp1.unit_code
                             and uc1.to_unit_id =
                                      substr (
                                          r.native_units,
                                          1,
                                          instr (replace (r.native_units, ';', ','),
                                                    ','
                                                  )
                                          - 1
                                      )
                             and rs.rating_spec_code = r.rating_spec_code
                             and rt.template_code = rs.template_code
                             and p2.parameter_code = rt.dep_parameter_code
                             and bp2.base_parameter_code = p2.base_parameter_code
                             and uc2.from_unit_code = bp2.unit_code
                             and uc2.to_unit_id =
                                      substr (r.native_units,
                                                 instr (r.native_units, ';') + 1
                                                )) r1
                left outer join (select   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') as native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') as native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         from   at_parameter p1,
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
                                        where   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  and rips.parameter_position = 2
                                                  and rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  and p1.parameter_code =
                                                            rips.parameter_code
                                                  and bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  and r.rating_code = rip.rating_code
                                                  and uc1.from_unit_code = bp1.unit_code
                                                  and uc1.to_unit_id =
                                                            case instr (
                                                                      replace (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      2
                                                                  )
                                                                when 0
                                                                then
                                                                    null
                                                                else
                                                                    substr (
                                                                        r.native_units,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            1
                                                                        )
                                                                        + 1,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            2
                                                                        )
                                                                        - instr (
                                                                              replace (
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
                                                            end
                                                  and rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  and rt.template_code = rs.template_code
                                                  and p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  and bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  and uc2.from_unit_code = bp2.unit_code
                                                  and uc2.to_unit_id =
                                                            substr (
                                                                r.native_units,
                                                                instr (r.native_units, ';')
                                                                + 1
                                                            )) r2
                    on r2.rating_ind_param_code = r1.dep_rating_ind_param_code
                left outer join (select   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') as native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') as native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         from   at_parameter p1,
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
                                        where   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  and rips.parameter_position = 3
                                                  and rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  and p1.parameter_code =
                                                            rips.parameter_code
                                                  and bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  and r.rating_code = rip.rating_code
                                                  and uc1.from_unit_code = bp1.unit_code
                                                  and uc1.to_unit_id =
                                                            case instr (
                                                                      replace (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      3
                                                                  )
                                                                when 0
                                                                then
                                                                    null
                                                                else
                                                                    substr (
                                                                        r.native_units,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            2
                                                                        )
                                                                        + 1,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            3
                                                                        )
                                                                        - instr (
                                                                              replace (
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
                                                            end
                                                  and rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  and rt.template_code = rs.template_code
                                                  and p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  and bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  and uc2.from_unit_code = bp2.unit_code
                                                  and uc2.to_unit_id =
                                                            substr (
                                                                r.native_units,
                                                                instr (r.native_units, ';')
                                                                + 1
                                                            )) r3
                    on r3.rating_ind_param_code = r2.dep_rating_ind_param_code
                left outer join (select   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') as native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') as native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         from   at_parameter p1,
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
                                        where   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  and rips.parameter_position = 4
                                                  and rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  and p1.parameter_code =
                                                            rips.parameter_code
                                                  and bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  and r.rating_code = rip.rating_code
                                                  and uc1.from_unit_code = bp1.unit_code
                                                  and uc1.to_unit_id =
                                                            case instr (
                                                                      replace (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      4
                                                                  )
                                                                when 0
                                                                then
                                                                    null
                                                                else
                                                                    substr (
                                                                        r.native_units,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            3
                                                                        )
                                                                        + 1,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            4
                                                                        )
                                                                        - instr (
                                                                              replace (
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
                                                            end
                                                  and rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  and rt.template_code = rs.template_code
                                                  and p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  and bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  and uc2.from_unit_code = bp2.unit_code
                                                  and uc2.to_unit_id =
                                                            substr (
                                                                r.native_units,
                                                                instr (r.native_units, ';')
                                                                + 1
                                                            )) r4
                    on r4.rating_ind_param_code = r3.dep_rating_ind_param_code
                left outer join (select   rip.rating_ind_param_code,
                                                  rv.other_ind_hash, rv.ind_value,
                                                  rv.dep_value,
                                                  cwms_rounding.round_dd_f (rv.ind_value * uc1.factor + uc1.offset, '8888888888') as native_ind_value,
                                                  cwms_rounding.round_dd_f (rv.dep_value * uc2.factor + uc2.offset, '8888888888') as native_dep_value,
                                                  rv.dep_rating_ind_param_code
                                         from   at_parameter p1,
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
                                        where   rips.ind_param_spec_code =
                                                      rip.ind_param_spec_code
                                                  and rips.parameter_position = 5
                                                  and rv.rating_ind_param_code =
                                                            rip.rating_ind_param_code
                                                  and p1.parameter_code =
                                                            rips.parameter_code
                                                  and bp1.base_parameter_code =
                                                            p1.base_parameter_code
                                                  and r.rating_code = rip.rating_code
                                                  and uc1.from_unit_code = bp1.unit_code
                                                  and uc1.to_unit_id =
                                                            case instr (
                                                                      replace (r.native_units,
                                                                                  ';',
                                                                                  ','
                                                                                 ),
                                                                      ',',
                                                                      1,
                                                                      5
                                                                  )
                                                                when 0
                                                                then
                                                                    null
                                                                else
                                                                    substr (
                                                                        r.native_units,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            4
                                                                        )
                                                                        + 1,
                                                                        instr (
                                                                            replace (
                                                                                r.native_units,
                                                                                ';',
                                                                                ','
                                                                            ),
                                                                            ',',
                                                                            1,
                                                                            5
                                                                        )
                                                                        - instr (
                                                                              replace (
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
                                                            end
                                                  and rs.rating_spec_code =
                                                            r.rating_spec_code
                                                  and rt.template_code = rs.template_code
                                                  and p2.parameter_code =
                                                            rt.dep_parameter_code
                                                  and bp2.base_parameter_code =
                                                            p2.base_parameter_code
                                                  and uc2.from_unit_code = bp2.unit_code
                                                  and uc2.to_unit_id =
                                                            substr (
                                                                r.native_units,
                                                                instr (r.native_units, ';')
                                                                + 1
                                                            )) r5
                    on r5.rating_ind_param_code = r4.dep_rating_ind_param_code
     where    (r1.dep_value is null
                 or r1.other_ind_hash = rating_value_t.hash_other_ind (null))
                and (r2.dep_value is null
                      or r2.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value)
                              ))
                and (r3.dep_value is null
                      or r3.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value, r2.ind_value)
                              ))
                and (r4.dep_value is null
                      or r4.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value,
                                                     r2.ind_value,
                                                     r3.ind_value
                                                    )
                              ))
                and (r5.dep_value is null
                      or r5.other_ind_hash =
                              rating_value_t.hash_other_ind (
                                  double_tab_t (r1.ind_value,
                                                     r2.ind_value,
                                                     r3.ind_value,
                                                     r4.ind_value
                                                    )
                              ));

create index mv_rating_values_native_idx1 on mv_rating_values_native(rating_code);

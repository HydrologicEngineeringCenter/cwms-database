insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_RATING_VALUES', null,
'
/**
 * Displays rating values in database storage units
 *
 * @since CWMS 2.1
 *
 * @see view av_rating
 * @see view av_rating_local
 * @see view mv_rating_values_native
 *
 * @field rating_code Unique numeric code identifying rating
 * @field ind_value_1 The value for the first independent parameter in database storage unit
 * @field ind_value_2 The value for the second independent parameter, if any, in database storage unit
 * @field ind_value_3 The value for the third independent parameter, if any, in database storage unit
 * @field ind_value_4 The value for the fourth independent parameter, if any, in database storage unit
 * @field ind_value_5 The value for the fifth independent parameter, if any, in database storage unit
 * @field dep_value   The value for the dependent parameter in database storage unit
 */
');
create materialized view mv_rating_values
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
select distinct p1.rating_code,
                p1.ind_value as ind_value_1,
                p2.ind_value as ind_value_2,
                p3.ind_value as ind_value_3,
                p4.ind_value as ind_value_4,
                p5.ind_value as ind_value_5,
                coalesce (p1.dep_value, p2.dep_value, p3.dep_value, p4.dep_value, p5.dep_value) as dep_value
           from (select rip.rating_code,
                        rip.rating_ind_param_code,
                        rv.other_ind_hash,
                        rv.ind_value,
                        rv.dep_value,
                        rv.dep_rating_ind_param_code
                   from at_rating_ind_parameter rip,
                        at_rating_ind_param_spec rips,
                        at_rating_value rv
                  where rips.ind_param_spec_code = rip.ind_param_spec_code
                    and rips.parameter_position = 1
                    and rv.rating_ind_param_code = rip.rating_ind_param_code
                ) p1
                left outer join
                (select rip.rating_ind_param_code,
                        rv.other_ind_hash,
                        rv.ind_value,
                        rv.dep_value,
                        rv.dep_rating_ind_param_code
                   from at_rating_ind_parameter rip,
                        at_rating_ind_param_spec rips,
                        at_rating_value rv
                  where rips.ind_param_spec_code = rip.ind_param_spec_code
                    and rips.parameter_position = 2
                    and rv.rating_ind_param_code = rip.rating_ind_param_code
                ) p2
                on p2.rating_ind_param_code = p1.dep_rating_ind_param_code
                left outer join
                (select rip.rating_ind_param_code,
                        rv.other_ind_hash,
                        rv.ind_value,
                        rv.dep_value,
                        rv.dep_rating_ind_param_code
                   from at_rating_ind_parameter rip,
                        at_rating_ind_param_spec rips,
                        at_rating_value rv
                  where rips.ind_param_spec_code = rip.ind_param_spec_code
                    and rips.parameter_position = 3
                    and rv.rating_ind_param_code = rip.rating_ind_param_code
                ) p3
                on p3.rating_ind_param_code = p2.dep_rating_ind_param_code
                left outer join
                (select rip.rating_ind_param_code,
                        rv.other_ind_hash,
                        rv.ind_value,
                        rv.dep_value,
                        rv.dep_rating_ind_param_code
                   from at_rating_ind_parameter rip,
                        at_rating_ind_param_spec rips,
                        at_rating_value rv
                  where rips.ind_param_spec_code = rip.ind_param_spec_code
                    and rips.parameter_position = 4
                    and rv.rating_ind_param_code = rip.rating_ind_param_code
                ) p4
                on p4.rating_ind_param_code = p3.dep_rating_ind_param_code
                left outer join
                (select rip.rating_ind_param_code,
                        rv.other_ind_hash,
                        rv.ind_value,
                        rv.dep_value,
                        rv.dep_rating_ind_param_code
                   from at_rating_ind_parameter rip,
                        at_rating_ind_param_spec rips,
                        at_rating_value rv
                  where rips.ind_param_spec_code = rip.ind_param_spec_code
                    and rips.parameter_position = 5
                    and rv.rating_ind_param_code = rip.rating_ind_param_code
                ) p5
                on p5.rating_ind_param_code = p4.dep_rating_ind_param_code
          where (p1.dep_value is null or p1.other_ind_hash = rating_value_t.hash_other_ind(null))
            and (p2.dep_value is null or p2.other_ind_hash = rating_value_t.hash_other_ind(double_tab_t (p1.ind_value)))
            and (p3.dep_value is null or p3.other_ind_hash = rating_value_t.hash_other_ind(double_tab_t (p1.ind_value,p2.ind_value)))
            and (p4.dep_value is null or p4.other_ind_hash = rating_value_t.hash_other_ind(double_tab_t (p1.ind_value,p2.ind_value,p3.ind_value)))
            and (p5.dep_value is null or p5.other_ind_hash = rating_value_t.hash_other_ind(double_tab_t (p1.ind_value,p2.ind_value,p3.ind_value,p4.ind_value)));

create index mv_rating_values_idx1 on mv_rating_values(rating_code);

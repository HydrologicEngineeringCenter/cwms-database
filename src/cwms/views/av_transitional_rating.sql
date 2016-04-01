----------------------------
-- AV_TRANSITIONAL_RATING --
----------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TRANSITIONAL_RATING', null,
'
/**
 * Displays information on transitional ratings
 *
 * @since CWMS 3.1
 *
 * @field office_id                The office that owns the transitional rating
 * @field rating_spec              The rating specification for the transistional rating
 * @field native_units             The units used for the conditions and evaluations of the rating
 * @field effective_date           The date/time that the rating went into effect in UTC
 * @field create_date              The date/time that the rating was stored to the database in UTC
 * @field position                 The evaluation position for this condition/evaluation. Position 0 is the default evaluation if no conditions are specified, or no specified conditions are met.
 * @field condition                The condition for this evaluation position
 * @field expression               The evaluation expression for this position
 * @field source_rating_spec       The source rating specification if the evaluation expression is the output of one of the source ratings
 * @field transitional_rating_code The unique numeric code of this transitional rating
 * @field rating_spec_code         The unique numeric code of the the rating specification for this transitional rating
 * @field source_rating_spec_code  The unique numeric code of the source rating specification if the evaluation expression is the output of one of the source ratings
 * @field transition_date          The date/time to start transition (interpolation) from previous rating in UTC
 */
');
create or replace force view av_transitional_rating(
   office_id,
   rating_spec,
   native_units,
   effective_date,
   create_date,
   position,
   condition,
   expression,
   source_rating_spec,
   transitional_rating_code,
   rating_spec_code,
   source_rating_spec_code,
   transition_date)
as
   select a.office_id,
          a.rating_spec,
          a.native_units,
          a.effective_date,
          a.create_date,
          a.position,
          case
             when a.condition is null then null
             else regexp_replace(
                     cwms_util.to_algebraic_logic(
                        regexp_replace(
                           a.condition, 
                           'I(\d+)', 
                           'ARG\1')), 
                     'ARG(\d+)', 
                     'I\1')
          end
             as condition,
          regexp_replace(
             regexp_replace(
                cwms_util.to_algebraic(
                   regexp_replace(
                      regexp_replace(
                         a.expression, 
                         'R(\d+)', 
                         'ARG90\1'), 
                      'I(\d+)', 
                      'ARG\1')),
                'ARG90(\d+)',
                'R\1'),
             'ARG(\d+)',
             'I\1')
             as expression,
          b.source_rating_spec,
          a.transitional_rating_code,
          a.rating_spec_code,
          b.rating_spec_code as source_rating_spec_code,
          a.transition_date
     from (select tr.transitional_rating_code,
                  tr.rating_spec_code, 
                  tr.native_units,
                  tr.effective_date,
                  tr.create_date,
                  trs.position,
                  trs.condition,
                  trs.expression,
                  o.office_id,
                  bl.base_location_id
                  || substr('-', 1, length(pl.sub_location_id))
                  || pl.sub_location_id
                  || '.'
                  || rt.parameters_id
                  || '.'
                  || rt.version
                  || '.'
                  || rs.version
                     as rating_spec,
                  tr.transition_date
             from at_transitional_rating tr,
                  at_transitional_rating_sel trs,
                  at_rating_spec rs,
                  at_rating_template rt,
                  at_physical_location pl,
                  at_base_location bl,
                  cwms_office o
            where rs.rating_spec_code = tr.rating_spec_code
              and rt.template_code = rs.template_code
              and pl.location_code = rs.location_code
              and bl.base_location_code = pl.base_location_code
              and o.office_code = bl.db_office_code
              and trs.transitional_rating_code = tr.transitional_rating_code
          ) a
          left outer join
          (select trs1.transitional_rating_code,
                  trs1.rating_spec_code,
                  trs1.position,
                  trs2.expression,
                  bl.base_location_id
                  || substr('-', 1, length(pl.sub_location_id))
                  || pl.sub_location_id
                  || '.'
                  || rt.parameters_id
                  || '.'
                  || rt.version
                  || '.'
                  || rs.version
                     as source_rating_spec
             from at_transitional_rating_src trs1,
                  at_transitional_rating_sel trs2,
                  at_rating_spec rs,
                  at_rating_template rt,
                  at_physical_location pl,
                  at_base_location bl
            where rs.rating_spec_code = trs1.rating_spec_code
              and trs2.transitional_rating_code = trs1.transitional_rating_code
              and length(trs2.expression) = 2
              and rt.template_code = rs.template_code
              and pl.location_code = rs.location_code
              and bl.base_location_code = pl.base_location_code
          ) b on a.transitional_rating_code = b.transitional_rating_code
             and a.expression = b.expression 
             and to_number(substr(b.expression, 2)) = b.position;

CREATE OR REPLACE PUBLIC SYNONYM CWMS_V_TRANSITIONAL_RATING FOR AV_TRANSITIONAL_RATING;

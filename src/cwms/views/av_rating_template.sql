------------------------
-- AV_RATING_TEMPLATE --
------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_TEMPLATE', null,
'
/**
 * Displays information about rating templates
 *
 * @since CWMS 2.1
 *
 * @see view av_rating_spec
 *
 * @field office_id              Office that owns the template
 * @field template_id            The rating template identifier
 * @field parameters_id          The parameters used by the template
 * @field independent_parameters The independent parameter(s) used by the template
 * @field dependent_parameter    The dependent parameter used by the template
 * @field version                The template version
 * @field description            A description for the template
 * @field rating_methods         Specifies the behavior of any rating associated with this template when looking up independent parameters
 * @field tempalate_code         The unique numeric code that identifies the template in the database.
 */
');

CREATE OR REPLACE FORCE VIEW av_rating_template
(
    office_id,
    template_id,
    parameters_id,
    independent_parameters,
    dependent_parameter,
    version,
    description,
    rating_methods,
    template_code
)
AS
    SELECT    DISTINCT office_id, template_id, parameters_id,
                            independent_parameters, dependent_parameter, version,
                            description, rating_methods, a.template_code
      FROM        (SELECT     rt.template_code, o.office_id,
                                 rt.parameters_id || '.' || rt.version AS template_id,
                                 rt.parameters_id,
                                 SUBSTR (rt.parameters_id, 1, INSTR (rt.parameters_id, ';') - 1) AS independent_parameters,
                                 SUBSTR (rt.parameters_id, INSTR (rt.parameters_id, ';') + 1) AS dependent_parameter,
                                 rt.version, rt.description
                        FROM     at_rating_template rt, cwms_office o
                      WHERE     o.office_code = rt.office_code) a
                JOIN
                    (SELECT     p1.template_code,
                                 p1.rating_methods || SUBSTR ('/', 1, LENGTH (p2.rating_methods)) || p2.rating_methods || SUBSTR ('/', 1, LENGTH (p3.rating_methods)) || p3.rating_methods || SUBSTR ('/', 1, LENGTH (p4.rating_methods)) || p4.rating_methods || SUBSTR ('/', 1, LENGTH (p5.rating_methods)) || p5.rating_methods AS rating_methods
                        FROM     (SELECT   template_code, parameter_position,
                                              rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS rating_methods
                                     FROM   at_rating_ind_param_spec rips,
                                              cwms_rating_method rm1,
                                              cwms_rating_method rm2,
                                              cwms_rating_method rm3
                                    WHERE   rm1.rating_method_code =
                                                  rips.in_range_rating_method
                                              AND rm2.rating_method_code =
                                                        rips.out_range_low_rating_method
                                              AND rm3.rating_method_code =
                                                        rips.out_range_high_rating_method
                                              AND parameter_position = 1) p1
                                 LEFT OUTER JOIN (SELECT    template_code,
                                                                    parameter_position,
                                                                    rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS rating_methods
                                                          FROM    at_rating_ind_param_spec rips,
                                                                    cwms_rating_method rm1,
                                                                    cwms_rating_method rm2,
                                                                    cwms_rating_method rm3
                                                         WHERE    rm1.rating_method_code =
                                                                        rips.in_range_rating_method
                                                                    AND rm2.rating_method_code =
                                                                             rips.out_range_low_rating_method
                                                                    AND rm3.rating_method_code =
                                                                             rips.out_range_high_rating_method
                                                                    AND parameter_position = 2) p2
                                     ON p2.template_code = p1.template_code
                                 LEFT OUTER JOIN (SELECT    template_code,
                                                                    parameter_position,
                                                                    rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS rating_methods
                                                          FROM    at_rating_ind_param_spec rips,
                                                                    cwms_rating_method rm1,
                                                                    cwms_rating_method rm2,
                                                                    cwms_rating_method rm3
                                                         WHERE    rm1.rating_method_code =
                                                                        rips.in_range_rating_method
                                                                    AND rm2.rating_method_code =
                                                                             rips.out_range_low_rating_method
                                                                    AND rm3.rating_method_code =
                                                                             rips.out_range_high_rating_method
                                                                    AND parameter_position = 3) p3
                                     ON p3.template_code = p1.template_code
                                 LEFT OUTER JOIN (SELECT    template_code,
                                                                    parameter_position,
                                                                    rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS rating_methods
                                                          FROM    at_rating_ind_param_spec rips,
                                                                    cwms_rating_method rm1,
                                                                    cwms_rating_method rm2,
                                                                    cwms_rating_method rm3
                                                         WHERE    rm1.rating_method_code =
                                                                        rips.in_range_rating_method
                                                                    AND rm2.rating_method_code =
                                                                             rips.out_range_low_rating_method
                                                                    AND rm3.rating_method_code =
                                                                             rips.out_range_high_rating_method
                                                                    AND parameter_position = 4) p4
                                     ON p4.template_code = p1.template_code
                                 LEFT OUTER JOIN (SELECT    template_code,
                                                                    parameter_position,
                                                                    rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS rating_methods
                                                          FROM    at_rating_ind_param_spec rips,
                                                                    cwms_rating_method rm1,
                                                                    cwms_rating_method rm2,
                                                                    cwms_rating_method rm3
                                                         WHERE    rm1.rating_method_code =
                                                                        rips.in_range_rating_method
                                                                    AND rm2.rating_method_code =
                                                                             rips.out_range_low_rating_method
                                                                    AND rm3.rating_method_code =
                                                                             rips.out_range_high_rating_method
                                                                    AND parameter_position = 5) p5
                                     ON p5.template_code = p1.template_code) b
                ON b.template_code = a.template_code;

/
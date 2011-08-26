--------------------
-- AV_RATING_SPEC --
--------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_SPEC', null,
'
/**
 * Displays information on ratings specifications
 *
 * @since CWMS 2.1
 *
 * @see CWMS_ROUNDING
 *
 * @field office_id             The office owning the rating spec
 * @field rating_id             The rating spec identifier
 * @field location_id           The location for the rating spec
 * @field template_id           The rating template identifier for this rating spec
 * @field source_agency         The agency that supplies ratings for this rating spec
 * @field version               The version identifier for this rating spec
 * @field active_flag           Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether this rating spec is active
 * @field auto_update_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether new ratings under this spec automatically be loaded
 * @field auto_activate_flag    Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether newly loaded ratings under this spec should automatically be activated
 * @field auto_migrate_ext_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether newly loaded ratings under this spec should automatically inherit rating extenions from a previous rating
 * @field date_methods,         Specifies behavior rating methods will use when rating values with times before the earliest effective date, between first and last effective dates, and after last effective date
 * @field ind_rounding_specs    Specifies USGS-style rounding specification(s) for displaying independent parameter(s)
 * @field dep_rounding_spec     Specifies USGS-style rounding specification for displaying dependent parameter
 * @field description           The description for this rating specification
 */
');

CREATE OR REPLACE FORCE VIEW av_rating_spec
(
    office_id,
    rating_id,
    location_id,
    template_id,
    version,
    source_agency,
    active_flag,
    auto_update_flag,
    auto_activate_flag,
    auto_migrate_ext_flag,
    date_methods,
    ind_rounding_specs,
    dep_rounding_spec,
    description
)
AS
    SELECT    office_id, rating_id, location_id, template_id, version,
                source_agency, active_flag, auto_update_flag, auto_activate_flag,
                auto_migrate_ext_flag, date_methods, ind_rounding_specs,
                dep_rounding_spec, description
      FROM        (SELECT     rs.rating_spec_code, rs.template_code, o.office_id,
                                 bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id || '.' || rt.parameters_id || '.' || rt.version || '.' || rs.version AS rating_id,
                                 bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id AS location_id,
                                 rt.parameters_id || '.' || rt.version AS template_id,
                                 rs.version,
                                 REPLACE (lg.loc_group_id, 'Default', '') AS source_agency,
                                 rs.active_flag, rs.auto_update_flag,
                                 rs.auto_activate_flag, rs.auto_migrate_ext_flag,
                                 rm2.rating_method_id || ',' || rm1.rating_method_id || ',' || rm3.rating_method_id AS date_methods,
                                 rs.dep_rounding_spec, rs.description
                        FROM     at_rating_spec rs,
                                 at_rating_template rt,
                                 at_physical_location pl,
                                 at_loc_group lg,
                                 at_base_location bl,
                                 cwms_office o,
                                 cwms_rating_method rm1,
                                 cwms_rating_method rm2,
                                 cwms_rating_method rm3
                      WHERE          rt.template_code = rs.template_code
                                 AND pl.location_code = rs.location_code
                                 AND bl.base_location_code = pl.base_location_code
                                 AND o.office_code = bl.db_office_code
                                 AND lg.loc_group_code =
                                          NVL (rs.source_agency_code, 0)
                                 AND rm1.rating_method_code =
                                          rs.in_range_rating_method
                                 AND rm2.rating_method_code =
                                          rs.out_range_low_rating_method
                                 AND rm3.rating_method_code =
                                          rs.out_range_high_rating_method) a
                JOIN
                    (SELECT     p1.rating_spec_code,
                                 p1.rounding_spec || SUBSTR ('/', 1, LENGTH (p2.rounding_spec)) || p2.rounding_spec || SUBSTR ('/', 1, LENGTH (p3.rounding_spec)) || p3.rounding_spec || SUBSTR ('/', 1, LENGTH (p4.rounding_spec)) || p4.rounding_spec || SUBSTR ('/', 1, LENGTH (p5.rounding_spec)) || p5.rounding_spec AS ind_rounding_specs
                        FROM     (SELECT   rating_spec_code, rounding_spec
                                     FROM   at_rating_ind_rounding
                                    WHERE   parameter_position = 1) p1
                                 LEFT OUTER JOIN (SELECT    rating_spec_code,
                                                                    rounding_spec
                                                          FROM    at_rating_ind_rounding
                                                         WHERE    parameter_position = 2) p2
                                     ON p2.rating_spec_code = p1.rating_spec_code
                                 LEFT OUTER JOIN (SELECT    rating_spec_code,
                                                                    rounding_spec
                                                          FROM    at_rating_ind_rounding
                                                         WHERE    parameter_position = 3) p3
                                     ON p3.rating_spec_code = p1.rating_spec_code
                                 LEFT OUTER JOIN (SELECT    rating_spec_code,
                                                                    rounding_spec
                                                          FROM    at_rating_ind_rounding
                                                         WHERE    parameter_position = 4) p4
                                     ON p4.rating_spec_code = p1.rating_spec_code
                                 LEFT OUTER JOIN (SELECT    rating_spec_code,
                                                                    rounding_spec
                                                          FROM    at_rating_ind_rounding
                                                         WHERE    parameter_position = 5) p5
                                     ON p5.rating_spec_code = p1.rating_spec_code) b
                ON b.rating_spec_code = a.rating_spec_code;

/

---------------------
-- AV_RATING_LOCAL --
---------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_LOCAL', null,
'
/**
 * Displays information on ratings in the local time zone of the rating''s location
 *
 * @since CWMS 2.1
 *
 * @see CWMS_ROUNDING
 *
 * @field rating_code        Unique numeric code identifying the rating
 * @field parent_rating_code Unique numeric code identifying the parent of this rating, if any
 * @field office_id          The office owning the rating
 * @field rating_id          The rating identifier
 * @field location_id        The location for the rating
 * @field template_id        The rating template identifier for this rating
 * @field version            The version identifier for this rating
 * @field native_units       The native units for each parameter for this rating
 * @field effective_date     The date/time that this rating goes/went into effect in the local time zone of the rating''s location
 * @field create_date        The date/time that this rating was loaded into the database in the local time zone of the rating''s location
 * @field active_flag        Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether this rating is active
 * @field formula            The formula for this rating if it is formula-based
 * @field description        The description for this rating
 */
');

CREATE OR REPLACE FORCE VIEW av_rating_local
(
    rating_code,
    parent_rating_code,
    office_id,
    rating_id,
    location_id,
    template_id,
    version,
    native_units,
    effective_date,
    create_date,
    active_flag,
    formula,
    description
)
AS
    SELECT    r.rating_code, r.ref_rating_code AS parent_rating_code,
                o.office_id,
                bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id || '.' || rt.parameters_id || '.' || rt.version || '.' || rs.version AS rating_id,
                bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id AS location_id,
                rt.parameters_id || '.' || rt.version AS template_id, rs.version,
                r.native_units,
                cwms_util.change_timezone (r.effective_date, 'UTC', tz.time_zone_name) AS effective_date,
                cwms_util.change_timezone (r.create_date, 'UTC', tz.time_zone_name) AS create_date,
                r.active_flag, r.formula, r.description
      FROM    at_rating r,
                at_rating_spec rs,
                at_rating_template rt,
                at_physical_location pl,
                at_base_location bl,
                cwms_office o,
                cwms_time_zone tz
     WHERE         rs.rating_spec_code = r.rating_spec_code
                AND rt.template_code = rs.template_code
                AND pl.location_code = rs.location_code
                AND bl.base_location_code = pl.base_location_code
                AND o.office_code = bl.db_office_code
                AND tz.time_zone_code = NVL (pl.time_zone_code, 0);

/
-----------------------------
-- AV_TS_ASSOCIATION--
-----------------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_ASSOCIATION', null,
'
/**
 * Displays information about time series associations
 *
 * @since CWMS 2.1
 *
 * @field office_id         Office for which the association applies
 * @field association_type  Indicates whether the association is for a location or location group
 * @field usage_category_id The general usage for the association
 * @field usage_id          The specific usage for the association
 * @field association_id    The location or location group
 * @field timeseries_id     The associated time series
 * @field usage_description The description of the association
 */
');

CREATE OR REPLACE FORCE VIEW av_ts_association
(
    office_id,
    association_type,
    usage_category_id,
    usage_id,
    association_id,
    timeseries_id,
    usage_description
)
AS
    SELECT    o.office_id office_id, p.prop_category association_type,
                cwms_util.split_text (p.prop_id, 1, '.') usage_category_id,
                cwms_util.split_text (p.prop_id, 2, '.') usage_id,
                cwms_util.split_text (p.prop_id, 3, '.') association_id,
                p.prop_value timeseries_id, p.prop_comment usage_description
      FROM    at_properties p
                INNER JOIN at_properties ip
                    ON (      p.office_code = ip.office_code
                         AND p.prop_category = ip.prop_category
                         AND p.prop_id = ip.prop_id
                         AND p.prop_category IN
                                  ('LOCATION TIME SERIES ASSOCIATION',
                                    'LOCATION GROUP TIME SERIES ASSOCIATION'))
                INNER JOIN cwms_office o
                    ON p.office_code = o.office_code
--where prop_category in ('LOCATION TIME SERIES ASSOCIATION', 'LOCATION GROUP TIME SERIES ASSOCIATION');
/
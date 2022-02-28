insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_CAT_GRP', null,
'
/**
 * Displays information about time series categories and groups
 *
 * @since CWMS 2.1
 *
 * @field cat_db_office_id   Office that owns the time series category
 * @field ts_category_id     Time series category (parent of time series group)
 * @field ts_category_desc   Description of time series category
 * @field grp_db_office_id   Office that owns the time series group
 * @field ts_group_id        Time series group identifier
 * @field ts_group_desc      Description of the time series group
 * @field shared_ts_alias_id The alias, if any, shared by all members of the time series group
 * @field shared_ref_ts_id   The referenced time series, if any, shared by all members of the time series group
 */
');
CREATE OR REPLACE VIEW av_ts_cat_grp
(
	cat_db_office_id,
	ts_category_id,
	ts_category_desc,
	grp_db_office_id,
	ts_group_id,
	ts_group_desc,
	shared_ts_alias_id,
	shared_ref_ts_id
)
AS
   select o1.office_id as cat_db_office_id,
          ts_category_id,
          ts_category_desc,
          o2.office_id as grp_db_office_id,
          ts_group_id,
          ts_group_desc,
          shared_ts_alias_id,
          case
            when shared_ts_ref_code is null then null
            else cwms_ts.get_ts_id(shared_ts_ref_code)
          end as shared_ref_ts_id
     from cwms_office o1,
          cwms_office o2,
          at_ts_category attc,
          at_ts_group attg,
          at_cwms_ts_spec atcts
    where attc.db_office_code = o1.office_code and attg.db_office_code = o2.office_code(+) and attc.ts_category_code = attg.ts_category_code(+) and atcts.ts_code(+) = attg.shared_ts_ref_code;
/

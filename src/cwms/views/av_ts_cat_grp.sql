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
	SELECT	o1.office_id AS cat_db_office_id, ts_category_id,
				ts_category_desc, o2.office_id AS grp_db_office_id, ts_group_id,
				ts_group_desc, shared_ts_alias_id,
				cwms_ts.get_cwms_ts_id (shared_ts_ref_code, o2.office_id) AS shared_ref_ts_id
	  FROM	cwms_office o1,
				cwms_office o2,
				at_ts_category attc,
				at_ts_group attg,
				at_cwms_ts_spec atcts
	 WHERE		 attc.db_office_code = o1.office_code
				AND attg.db_office_code = o2.office_code(+)
				AND attc.ts_category_code = attg.ts_category_code(+)
				AND atcts.ts_code(+) = attg.shared_ts_ref_code
/

SHOW ERRORS;
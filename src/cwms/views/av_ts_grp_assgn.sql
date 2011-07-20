/* Formatted on 7/19/2011 5:54:21 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE VIEW av_ts_grp_assgn
(
	category_id,
	GROUP_ID,
	ts_code,
	db_office_id,
	ts_id,
	alias_id,
	attribute,
	ref_ts_id,
	shared_alias_id,
	shared_ref_ts_id
)
AS
	SELECT	atc.ts_category_id, atg.ts_group_id, atga.ts_code,
				co.office_id AS db_office_id,
				cwms_ts.get_cwms_ts_id (acts.ts_code, co.office_id) AS ts_id,
				atga.ts_alias_id, atga.ts_attribute,
				cwms_ts.get_cwms_ts_id (acts2.ts_code, co.office_id) AS ref_ts_id,
				atg.shared_ts_alias_id,
				cwms_ts.get_cwms_ts_id (acts3.ts_code, co.office_id) AS shared_ref_ts_id
	  FROM	at_cwms_ts_spec acts,
				at_ts_group_assignment atga,
				at_ts_group atg,
				at_ts_category atc,
				at_physical_location pl,
				at_base_location bl,
				cwms_office co,
				at_cwms_ts_spec acts2,
				at_cwms_ts_spec acts3
	 WHERE		 pl.location_code = acts.location_code
				AND bl.base_location_code = pl.base_location_code
				AND co.office_code = bl.db_office_code
				AND atga.ts_code = acts.ts_code
				AND atga.ts_group_code = atg.ts_group_code
				AND atg.ts_category_code = atc.ts_category_code
				AND acts2.ts_code(+) = atga.ts_ref_code
				AND acts3.ts_code(+) = atg.shared_ts_ref_code
/

SHOW ERRORS;
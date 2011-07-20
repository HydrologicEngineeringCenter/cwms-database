CREATE OR REPLACE VIEW av_ts_alias
(
	category_id,
	GROUP_ID,
	ts_code,
	db_office_id,
	ts_id,
	alias_id
)
AS
	SELECT	atc.ts_category_id, atg.ts_group_id, atga.ts_code,
				co.office_id AS db_office_id,
				cwms_ts.get_cwms_ts_id (acts.ts_code, co.office_id) AS ts_id,
				atga.ts_alias_id
	  FROM	at_cwms_ts_spec acts,
				at_ts_group_assignment atga,
				at_ts_group atg,
				at_ts_category atc,
				at_physical_location pl,
				at_base_location bl,
				cwms_office co
	 WHERE		 pl.location_code = acts.location_code
				AND bl.base_location_code = pl.base_location_code
				AND co.office_code = bl.db_office_code
				AND atga.ts_code = acts.ts_code
				AND atga.ts_group_code = atg.ts_group_code
				AND atg.ts_category_code = atc.ts_category_code
/

SHOW ERRORS;
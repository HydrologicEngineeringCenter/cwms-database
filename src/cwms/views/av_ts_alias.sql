insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_ALIAS', null,
'
/**
 * Displays information about time series aliases
 *
 * @since CWMS 2.1
 *
 * @field category_id   Time series category (parent of time series group)
 * @field group_id      Time series group (child of time series category)
 * @field ts_code       Unique number identifying the time series
 * @field db_office_id  Office owning the time series
 * @field ts_id         The time series
 * @field alias_id      The alias for the time series in this category/group
 */
');
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
				cwms_ts.get_ts_id (acts.ts_code) AS ts_id,
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
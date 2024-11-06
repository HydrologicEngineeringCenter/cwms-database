insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_GRP_ASSGN', null,
'
/**
 * Displays information on time series group membership
 *
 * @since CWMS 2.1
 *
 * @field category_id      time series category (parent of time series group)
 * @field group_id         time series group (child of time series group)
 * @field ts_code          Unique numeric code identfying the time series
 * @field db_office_id     Office that owns the time series
 * @field ts_id            The time series identifier
 * @field alias_id         The alias, if any, for the time series in this time series group
 * @field attribute        The numeric attribute, if any, for this time series with respect to the time series group (can be used for ordering, etc...)
 * @field ref_ts_id        The referenced time series, if any, for this time series with repect to the time series group
 * @field shared_alias_id  The alias, if any, shared by all members of the time series group
 * @field shared_ref_ts_id The referenced time series, if any, shared by all members of the time series group
 */
');
CREATE OR REPLACE VIEW av_ts_grp_assgn
(
   category_id,
   category_office_id,
   GROUP_ID,
   group_office_id,
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
   SELECT   atc.ts_category_id,
      atc.db_office_code as category_office_id,
      atg.ts_group_id,
      atg.db_office_code as group_office_id,
      atga.ts_code,
      co_loc.office_id AS db_office_id,
      cwms_ts.get_ts_id (acts.ts_code) AS ts_id,
      atga.ts_alias_id, atga.ts_attribute,
      case
         when acts2.ts_code is null then null
         else cwms_ts.get_ts_id (acts2.ts_code)
      end AS ref_ts_id,
      atg.shared_ts_alias_id,
      case
         when acts3.ts_code is null then null
         else cwms_ts.get_ts_id (acts3.ts_code)
      end AS shared_ref_ts_id
   FROM   at_cwms_ts_spec acts
      INNER JOIN at_ts_group_assignment atga ON atga.ts_code = acts.ts_code
      INNER JOIN at_ts_group atg ON atga.ts_group_code = atg.ts_group_code
      INNER JOIN at_ts_category atc ON atg.ts_category_code = atc.ts_category_code
      INNER JOIN at_physical_location pl ON pl.location_code = acts.location_code
      INNER JOIN at_base_location bl ON bl.base_location_code = pl.base_location_code
      LEFT JOIN at_cwms_ts_spec acts2 ON acts2.ts_code = atga.ts_ref_code
      LEFT JOIN at_cwms_ts_spec acts3 ON acts3.ts_code = atg.shared_ts_ref_code
      INNER JOIN cwms_office co_loc ON co_loc.office_code = bl.db_office_code
      INNER JOIN cwms_office co_atc ON co_atc.office_code = atc.db_office_code
      INNER JOIN cwms_office co_atg ON co_atg.office_code = atg.db_office_code
/

SHOW ERRORS;
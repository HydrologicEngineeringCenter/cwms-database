--
-- AV_STATE  (View)
--
--  Dependencies:
--   AT_BASE_LOCATION (Table)
--   CWMS_OFFICE (Table)
--   CWMS_STATE (Table)
--   CWMS_COUNTY (Table)
--   AT_PHYSICAL_LOCATION (Table)
--
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATE', null,
'
/**
 * Displays states that offices have locations in / offices that have locations in states
 *
 * @since CWMS 2.1
 *
 * @field state_initial The two letter abbreviation of the state
 * @field db_office_id  The office that has one or more location in the state
 */
');

CREATE OR REPLACE FORCE VIEW av_state
(
    state_initial,
    db_office_id
)
AS
    SELECT    DISTINCT cs.state_initial, co.office_id db_office_id
      FROM    at_physical_location apl,
                at_base_location abl,
                cwms_county cc,
                cwms_state cs,
                cwms_office co
     WHERE         apl.base_location_code = abl.base_location_code
                AND apl.county_code = cc.county_code
                AND cc.state_code = cs.state_code
                AND abl.db_office_code = co.db_host_office_code
/

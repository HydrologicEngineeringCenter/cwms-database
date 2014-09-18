insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_USACE_DAM_COUNTY', null,
'
/**
 * Displays AV_USACE_DAM_COUNTY information
 *
 * @since CWMS 2.1
 *
 * @field COUNTY_ID                  The..
 * @field STATE_ID                   The..
 * @field COUNTY_NAME                The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_USACE_DAM_COUNTY
(
   COUNTY_ID,
   STATE_ID,
   COUNTY_NAME
)
AS
   SELECT "COUNTY_ID", "STATE_ID", "COUNTY_NAME" FROM CWMS_USACE_DAM_COUNTY
/

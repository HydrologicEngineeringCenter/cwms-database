insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_USACE_DAM_STATE', null,
'
/**
 * Displays AV_USACE_DAM_STATE information
 *
 * @since CWMS 2.1
 *
 * @field   STATE_ID                 The..
 * @field   STATE_NAME               The..
 * @field   STATE_ABBR               The..
 * @field   DISTRICT_ID              The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_USACE_DAM_STATE
(
   STATE_ID,
   STATE_NAME,
   STATE_ABBR,
   DISTRICT_ID
)
AS
   SELECT "STATE_ID",
          "STATE_NAME",
          "STATE_ABBR",
          "DISTRICT_ID"
     FROM CWMS_USACE_DAM_STATE
/

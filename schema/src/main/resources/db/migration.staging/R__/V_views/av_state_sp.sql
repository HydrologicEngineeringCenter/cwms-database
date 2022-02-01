insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATE_SP', null,
'
/**
 * Displays AV_STATE_SP information
 *
 * @since CWMS 2.1
 *
 * @field STATE_CODE                 The..
 * @field OBJECTID                   The..
 * @field AREA                       The..
 * @field STATE_NAME                 The..
 * @field STATE_FIPS                 The..
 * @field SUB_REGION                 The..
 * @field STATE_ABBR                 The..
 * @field SHAPE                      The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_STATE_SP
(
   STATE_CODE,
   OBJECTID,
   AREA,
   STATE_NAME,
   STATE_FIPS,
   SUB_REGION,
   STATE_ABBR,
   SHAPE
)
AS
   SELECT STATE_CODE,
          OBJECTID,
          AREA,
          STATE_NAME,
          STATE_FIPS,
          SUB_REGION,
          STATE_ABBR,
          SHAPE
     FROM cwms_state_sp
/

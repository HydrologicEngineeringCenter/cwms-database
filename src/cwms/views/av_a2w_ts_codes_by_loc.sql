insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 2.1
 *
 * @field LOCATION_ID                The...
 * @field DB_OFFICE_ID               The...
 * @field TS_CODE_ELEV               The...
 * @field TS_CODE_PRECIP             The...
 * @field TS_CODE_STAGE              The...
 * @field TS_CODE_INFLOW             The...
 * @field TS_CODE_OUTFLOW            The...
 * @field DATE_REFRESHED             The...
 * @field TS_CODE_STOR_FLOOD         The...
 * @field NOTES                      The...
 * @field DISPLAY_FLAG               The...
 * @field NUM_TS_CODES               The...
 * @field TS_CODE_STOR_DROUGHT       The...
 * @field LAKE_SUMMARY_TF            The...
 * @field TS_CODE_SUR_RELEASE        The...
 */
');
CREATE OR REPLACE FORCE VIEW AV_A2W_TS_CODES_BY_LOC
(
   LOCATION_ID,
   DB_OFFICE_ID,
   TS_CODE_ELEV,
   TS_CODE_PRECIP,
   TS_CODE_STAGE,
   TS_CODE_INFLOW,
   TS_CODE_OUTFLOW,
   DATE_REFRESHED,
   TS_CODE_STOR_FLOOD,
   NOTES,
   DISPLAY_FLAG,
   NUM_TS_CODES,
   TS_CODE_STOR_DROUGHT,
   LAKE_SUMMARY_TF,
   TS_CODE_SUR_RELEASE
)
AS
   SELECT LOCATION_ID,
          DB_OFFICE_ID,
          TS_CODE_ELEV,
          TS_CODE_PRECIP,
          TS_CODE_STAGE,
          TS_CODE_INFLOW,
          TS_CODE_OUTFLOW,
          DATE_REFRESHED,
          TS_CODE_STOR_FLOOD,
          NOTES,
          DISPLAY_FLAG,
          NUM_TS_CODES,
          TS_CODE_STOR_DROUGHT,
          LAKE_SUMMARY_TF,
          TS_CODE_SUR_RELEASE
     FROM at_a2w_ts_codes_by_loc
/

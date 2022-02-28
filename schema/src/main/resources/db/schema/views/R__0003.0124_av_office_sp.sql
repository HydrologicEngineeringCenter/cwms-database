/**
 * Displays Office Information
 *
 * @since CWMS 2.1
 *
 * @field office_id             The text identifier of the office
 * @field office_code           The unique numeric code that identifies the office in the database
 * @field eroc                  The office''s Corps of Engineers Reporting Organization Code as per ER-37-1-27.
 * @field office_type           UNK=unknown, HQ=corps headquarters, MSC=division headquarters, MSCR=division regional, DIS=district, FOA=field operating activity
 * @field long_name             The office''s descriptive name
 * @field db_host_office_id     The text identifier of the office that hosts the database for this office
 * @field db_host_office_code   The unique numeric code that identifies in the database the office that hosts the database for this office
 * @field report_to_office_id   The text identifier of the office that this office reports to in the organizational hierarchy
 * @field report_to_office_code The unique numeric code that identifies in the database the office that this office reports to in the organizational hierarchy
 * @field shape                 Office Boundary
 * @field shape_office_building Office Building Boundary
 */
CREATE OR REPLACE FORCE VIEW AV_OFFICE_SP
(
   OFFICE_ID,
   OFFICE_CODE,
   EROC,
   OFFICE_TYPE,
   LONG_NAME,
   DB_HOST_OFFICE_ID,
   DB_HOST_OFFICE_CODE,
   REPORT_TO_OFFICE_ID,
   REPORT_TO_OFFICE_CODE,
   SHAPE,
   SHAPE_OFFICE_BUILDING
)
AS
   SELECT aa.OFFICE_ID,
          OFFICE_CODE,
          aa.EROC,
          aa.OFFICE_TYPE,
          aa.LONG_NAME,
          aa.office_id DB_HOST_OFFICE_ID,
          aa.DB_HOST_OFFICE_CODE,
          aa.office_id REPORT_TO_OFFICE_ID,
          aa.REPORT_TO_OFFICE_CODE,
          bb.shape,
          cc.shape shape_office_building
     FROM (SELECT a.OFFICE_ID,
                  a.OFFICE_CODE,
                  a.EROC,
                  a.OFFICE_TYPE,
                  a.LONG_NAME,
                  d.office_id DB_HOST_OFFICE_ID,
                  a.DB_HOST_OFFICE_CODE,
                  e.office_id REPORT_TO_OFFICE_ID,
                  a.REPORT_TO_OFFICE_CODE
             FROM cwms_office a
                  JOIN cwms_office d
                     ON (d.office_code = a.db_host_office_code)
                  JOIN cwms_office e
                     ON (e.office_code = a.report_to_office_code)) aa
          LEFT OUTER JOIN cwms_agg_district bb
             USING (office_code)
          LEFT OUTER JOIN cwms_offices_geoloc cc
             USING (office_code)
/

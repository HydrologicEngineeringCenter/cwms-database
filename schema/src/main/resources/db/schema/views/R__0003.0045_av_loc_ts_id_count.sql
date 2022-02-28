/**
 * Displays the number of time series associated with each location
 *
 * @since CWMS 2.1
 *
 * @field location_id   The text identifier of the location
 * @field ts_id_count   The number of time series identifiers associated with the location
 * @field location_code The unique numeric code associated with the location
 * @field db_office_id  The office that owns the location
 */
CREATE OR REPLACE FORCE VIEW CWMS_20.AV_LOC_TS_ID_COUNT
(
   LOCATION_ID,
   TS_ID_COUNT,
   LOCATION_CODE,
   DB_OFFICE_ID
)
AS
   SELECT    base_location_id
          || SUBSTR ('-', 1, LENGTH (sub_location_id))
          || sub_location_id
             location_id,
          NVL (num_ts_ids, 0) ts_id_count,
          location_code,
          co.office_id db_office_id
     FROM at_physical_location apl
          JOIN at_base_location abl
             USING (base_location_code)
          JOIN cwms_office co
             ON db_office_code = co.office_code
          LEFT JOIN (  SELECT location_code, COUNT (*) num_ts_ids
                         FROM at_cwms_ts_id acti
                     GROUP BY location_code)
             USING (location_code)
    WHERE location_code != 0;

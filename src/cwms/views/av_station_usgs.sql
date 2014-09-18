insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATION_USGS', null,
'
/**
 * Displays AV_STATION_USGS information
 *
 * @since CWMS 2.1
 *
 * @field AGENCY_CD                  The..
 * @field STATION_ID                 The..
 * @field STATION_NAME               The..
 * @field SITE_TYPE_CODE             The..
 * @field LAT                        The..
 * @field LON                        The..
 * @field COORD_ACY_CD               The..
 * @field DATUM_HORIZONTAL           The..
 * @field ALT_VA                     The..
 * @field ALT_ACY_VA                 The..
 * @field DATUM_VERTICAL             The..
 * @field STATE_ABBR                 The..
 * @field SHAPE                      The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_STATION_USGS
(
   AGENCY_CD,
   STATION_ID,
   STATION_NAME,
   SITE_TYPE_CODE,
   LAT,
   LON,
   COORD_ACY_CD,
   DATUM_HORIZONTAL,
   ALT_VA,
   ALT_ACY_VA,
   DATUM_VERTICAL,
   STATE_ABBR,
   SHAPE
)
AS
   SELECT AGENCY_CD,
          STATION_ID,
          STATION_NAME,
          SITE_TYPE_CODE,
          LAT,
          LON,
          COORD_ACY_CD,
          DATUM_HORIZONTAL,
          ALT_VA,
          ALT_ACY_VA,
          DATUM_VERTICAL,
          STATE_ABBR,
          SHAPE
     FROM CWMS_STATION_USGS
/

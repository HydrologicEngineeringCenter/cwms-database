insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATION_NWS', null,
'
/**
 * Displays AV_STATION_NWS information
 *
 * @since CWMS 2.1
 *
 * @field NWS_ID                     The..
 * @field NWS_NAME                   The..
 * @field LAT                        The..
 * @field LON                        The..
 * @field SHAPE                      The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_STATION_NWS
(
   NWS_ID,
   NWS_NAME,
   LAT,
   LON,
   SHAPE
)
AS
   SELECT "NWS_ID",
          "NWS_NAME",
          "LAT",
          "LON",
          "SHAPE"
     FROM CWMS_STATION_NWS
/

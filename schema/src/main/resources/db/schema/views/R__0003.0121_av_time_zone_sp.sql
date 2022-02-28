/**
 * Displays AV_TIME_ZONE_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field ZONE                       The..
 * @field SHAPE                      The..
 */
CREATE OR REPLACE FORCE VIEW AV_TIME_ZONE_SP
(
   OBJECTID,
   ZONE,
   SHAPE
)
AS
   SELECT OBJECTID, ZONE, SHAPE FROM CWMS_TIME_ZONE_SP
/

/**
 * Displays AV_COUNTY_SP information
 *
 * @since CWMS 2.1
 *
 * @field COUNTY_CODE                The..
 * @field OBJECTID                   The..
 * @field STATE                      The..
 * @field COUNTY                     The..
 * @field FIPS                       The..
 * @field SQUARE_MIL                 The..
 * @field SHAPE                      The..
 */
CREATE OR REPLACE FORCE VIEW AV_COUNTY_SP
(
   COUNTY_CODE,
   OBJECTID,
   STATE,
   COUNTY,
   FIPS,
   SQUARE_MIL,
   SHAPE
)
AS
   SELECT county_code,
          OBJECTID,
          STATE,
          COUNTY,
          FIPS,
          SQUARE_MIL,
          SHAPE
     FROM CWMS_COUNTY_SP
/

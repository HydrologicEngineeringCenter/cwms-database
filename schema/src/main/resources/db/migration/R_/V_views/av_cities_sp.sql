insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CITIES_SP', null,
'
/**
 * Displays AV_CITIES_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field CITY_FIPS                  The..
 * @field CITY_NAME                  The..
 * @field STATE_FIPS                 The..
 * @field STATE_NAME                 The..
 * @field STATE_CITY                 The..
 * @field TYPE                       The..
 * @field CAPITAL                    The..
 * @field SHAPE                      The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_CITIES_SP
(
   OBJECTID,
   CITY_FIPS,
   CITY_NAME,
   STATE_FIPS,
   STATE_NAME,
   STATE_CITY,
   TYPE,
   CAPITAL,
   SHAPE
)
AS
   SELECT "OBJECTID",
          "CITY_FIPS",
          "CITY_NAME",
          "STATE_FIPS",
          "STATE_NAME",
          "STATE_CITY",
          "TYPE",
          "CAPITAL",
          "SHAPE"
     FROM cwms_cities_sp
/

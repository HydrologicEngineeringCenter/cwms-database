insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_NATION_SP', null,
'
/**
 * Displays AV_NATION_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field FIPS_CNTRY                 The..
 * @field GMI_CNTRY                  The..
 * @field ISO_2DIGIT                 The..
 * @field ISO_3DIGIT                 The..
 * @field CNTRY_NAME                 The..
 * @field LONG_NAME                  The..
 * @field SOVEREIGN                  The..
 * @field POP_CNTRY                  The..
 * @field CURR_TYPE                  The..
 * @field CURR_CODE                  The..
 * @field LANDLOCKED                 The..
 * @field SQKM                       The..
 * @field SQMI                       The..
 * @field COLOR_MAP                  The..
 * @field SHAPE                      The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_NATION_SP
(
   OBJECTID,
   FIPS_CNTRY,
   GMI_CNTRY,
   ISO_2DIGIT,
   ISO_3DIGIT,
   CNTRY_NAME,
   LONG_NAME,
   SOVEREIGN,
   POP_CNTRY,
   CURR_TYPE,
   CURR_CODE,
   LANDLOCKED,
   SQKM,
   SQMI,
   COLOR_MAP,
   SHAPE
)
AS
   SELECT "OBJECTID",
          "FIPS_CNTRY",
          "GMI_CNTRY",
          "ISO_2DIGIT",
          "ISO_3DIGIT",
          "CNTRY_NAME",
          "LONG_NAME",
          "SOVEREIGN",
          "POP_CNTRY",
          "CURR_TYPE",
          "CURR_CODE",
          "LANDLOCKED",
          "SQKM",
          "SQMI",
          "COLOR_MAP",
          "SHAPE"
     FROM cwms_nation_sp
/

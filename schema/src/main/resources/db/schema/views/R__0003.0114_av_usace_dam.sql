/**
 * Displays AV_USACE_DAM information
 *
 * @since CWMS 2.1
 *
 * @field DAM_ID                     The..
 * @field NID_ID                     The..
 * @field STATE_ID_CODE              The..
 * @field DAM_NAME                   The..
 * @field DISTRICT_ID                The..
 * @field STATE_ID                   The..
 * @field COUNTY_ID                  The..
 * @field CITY_ID                    The..
 * @field CITY_DISTANCE              The..
 * @field SECTION                    The..
 * @field LONGITUDE                  The..
 * @field LATITUDE                   The..
 * @field NON_FED_ON_FED_PROPERTY    The..
 * @field RIVER_NAME                 The..
 * @field OWNER_ID                   The..
 * @field HAZARD_CLASS_ID            The..
 * @field EAP_STATUS_ID              The..
 * @field INSPECTION_FREQUENCY       The..
 * @field YEAR_COMPLTED              The..
 * @field CONDITION_ID               The..
 * @field CONDITION_DETAIL           The..
 * @field CONDITION_DATE             The..
 * @field LAST_INSPECTION_DATE       The..
 * @field DAM_LENGTH                 The..
 * @field DAM_HEIGHT                 The..
 * @field STRUCTURAL_HEIGHT          The..
 * @field HYDRAULIC_HEIGHT           The..
 * @field MAX_DISCHARGE              The..
 * @field MAX_STORAGE                The..
 * @field NORMAL_STORAGE             The..
 * @field SURFACE_AREA               The..
 * @field DRAINAGE_AREA              The..
 * @field SPILLWAY_TYPE              The..
 * @field SPILLWAY_WIDTH             The..
 * @field DAM_VOLUME                 The..
 * @field NUM_LOCKS                  The..
 * @field LENGTH_LOCK                The..
 * @field WIDTH_LOCK                 The..
 * @field FED_FUNDED_ID              The..
 * @field FED_DESIGNED_ID            The..
 * @field FED_OWNED_ID               The..
 * @field FED_OPERATED_ID            The..
 * @field FED_CONSTRUCTED_ID         The..
 * @field FED_REGULATED_ID           The..
 * @field FED_INSPECTED_ID           The..
 * @field FED_OTHER_ID               The..
 * @field DATE_UPDATED               The..
 * @field UPDATED_BY                 The..
 * @field DAM_PHOTO                  The..
 * @field OTHER_STRUCTURE_ID         The..
 * @field NUM_SEPERATE_STRUCT        The..
 * @field EXEC_SUMMARY_PATH          The..
 * @field DELETED                    The..
 * @field DELETED_DESCRIPTION        The..
 * @field PROJECT_DSAC_EXEMPT        The..
 * @field BUSINESS_LINE_ID           The..
 * @field SHAPE                      The..
 */
CREATE OR REPLACE FORCE VIEW AV_USACE_DAM
(
   DAM_ID,
   NID_ID,
   STATE_ID_CODE,
   DAM_NAME,
   DISTRICT_ID,
   STATE_ID,
   COUNTY_ID,
   CITY_ID,
   CITY_DISTANCE,
   SECTION,
   LONGITUDE,
   LATITUDE,
   NON_FED_ON_FED_PROPERTY,
   RIVER_NAME,
   OWNER_ID,
   HAZARD_CLASS_ID,
   EAP_STATUS_ID,
   INSPECTION_FREQUENCY,
   YEAR_COMPLTED,
   CONDITION_ID,
   CONDITION_DETAIL,
   CONDITION_DATE,
   LAST_INSPECTION_DATE,
   DAM_LENGTH,
   DAM_HEIGHT,
   STRUCTURAL_HEIGHT,
   HYDRAULIC_HEIGHT,
   MAX_DISCHARGE,
   MAX_STORAGE,
   NORMAL_STORAGE,
   SURFACE_AREA,
   DRAINAGE_AREA,
   SPILLWAY_TYPE,
   SPILLWAY_WIDTH,
   DAM_VOLUME,
   NUM_LOCKS,
   LENGTH_LOCK,
   WIDTH_LOCK,
   FED_FUNDED_ID,
   FED_DESIGNED_ID,
   FED_OWNED_ID,
   FED_OPERATED_ID,
   FED_CONSTRUCTED_ID,
   FED_REGULATED_ID,
   FED_INSPECTED_ID,
   FED_OTHER_ID,
   DATE_UPDATED,
   UPDATED_BY,
   DAM_PHOTO,
   OTHER_STRUCTURE_ID,
   NUM_SEPERATE_STRUCT,
   EXEC_SUMMARY_PATH,
   DELETED,
   DELETED_DESCRIPTION,
   PROJECT_DSAC_EXEMPT,
   BUSINESS_LINE_ID,
   SHAPE
)
AS
   SELECT DAM_ID,
          NID_ID,
          STATE_ID_CODE,
          DAM_NAME,
          DISTRICT_ID,
          STATE_ID,
          COUNTY_ID,
          CITY_ID,
          CITY_DISTANCE,
          SECTION,
          LONGITUDE,
          LATITUDE,
          NON_FED_ON_FED_PROPERTY,
          RIVER_NAME,
          OWNER_ID,
          HAZARD_CLASS_ID,
          EAP_STATUS_ID,
          INSPECTION_FREQUENCY,
          YEAR_COMPLTED,
          CONDITION_ID,
          CONDITION_DETAIL,
          CONDITION_DATE,
          LAST_INSPECTION_DATE,
          DAM_LENGTH,
          DAM_HEIGHT,
          STRUCTURAL_HEIGHT,
          HYDRAULIC_HEIGHT,
          MAX_DISCHARGE,
          MAX_STORAGE,
          NORMAL_STORAGE,
          SURFACE_AREA,
          DRAINAGE_AREA,
          SPILLWAY_TYPE,
          SPILLWAY_WIDTH,
          DAM_VOLUME,
          NUM_LOCKS,
          LENGTH_LOCK,
          WIDTH_LOCK,
          FED_FUNDED_ID,
          FED_DESIGNED_ID,
          FED_OWNED_ID,
          FED_OPERATED_ID,
          FED_CONSTRUCTED_ID,
          FED_REGULATED_ID,
          FED_INSPECTED_ID,
          FED_OTHER_ID,
          DATE_UPDATED,
          UPDATED_BY,
          DAM_PHOTO,
          OTHER_STRUCTURE_ID,
          NUM_SEPERATE_STRUCT,
          EXEC_SUMMARY_PATH,
          DELETED,
          DELETED_DESCRIPTION,
          PROJECT_DSAC_EXEMPT,
          BUSINESS_LINE_ID,
          SHAPE
     FROM cwms_usace_dam
/

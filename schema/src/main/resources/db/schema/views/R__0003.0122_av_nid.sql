/**
 * Displays AV_NID information
 *
 * @since CWMS 2.1
 *
 * @field RECORDID                   The..
 * @field DAM_NAME                   The..
 * @field OTHER_DAM_NAME             The..
 * @field DAM_FORMER_NAME            The..
 * @field STATEID                    The..
 * @field NIDID                      The..
 * @field LONGITUDE                  The..
 * @field LATITUDE                   The..
 * @field SECTION                    The..
 * @field COUNTY                     The..
 * @field RIVER                      The..
 * @field CITY                       The..
 * @field DISTANCE                   The..
 * @field OWNER_NAME                 The..
 * @field USACE_CRITICAL             The..
 * @field OWNER_TYPE                 The..
 * @field DAM_DESIGNER               The..
 * @field PRIVATE_DAM                The..
 * @field DAM_TYPE                   The..
 * @field CORE                       The..
 * @field FOUNDATION                 The..
 * @field PURPOSES                   The..
 * @field YEAR_COMPLETED             The..
 * @field YEAR_MODIFIED              The..
 * @field DAM_LENGTH                 The..
 * @field DAM_HEIGHT                 The..
 * @field STRUCTURAL_HEIGHT          The..
 * @field HYDRAULIC_HEIGHT           The..
 * @field NID_HEIGHT                 The..
 * @field MAX_DISCHARGE              The..
 * @field MAX_STORAGE                The..
 * @field NORMAL_STORAGE             The..
 * @field NID_STORAGE                The..
 * @field SURFACE_AREA               The..
 * @field DRAINAGE_AREA              The..
 * @field SORT_CATEGORY              The..
 * @field SHAPE                      The..
 */
CREATE OR REPLACE FORCE VIEW AV_NID
(
   RECORDID,
   DAM_NAME,
   OTHER_DAM_NAME,
   DAM_FORMER_NAME,
   STATEID,
   NIDID,
   LONGITUDE,
   LATITUDE,
   SECTION,
   COUNTY,
   RIVER,
   CITY,
   DISTANCE,
   OWNER_NAME,
   USACE_CRITICAL,
   OWNER_TYPE,
   DAM_DESIGNER,
   PRIVATE_DAM,
   DAM_TYPE,
   CORE,
   FOUNDATION,
   PURPOSES,
   YEAR_COMPLETED,
   YEAR_MODIFIED,
   DAM_LENGTH,
   DAM_HEIGHT,
   STRUCTURAL_HEIGHT,
   HYDRAULIC_HEIGHT,
   NID_HEIGHT,
   MAX_DISCHARGE,
   MAX_STORAGE,
   NORMAL_STORAGE,
   NID_STORAGE,
   SURFACE_AREA,
   DRAINAGE_AREA,
   SORT_CATEGORY,
   SHAPE
)
AS
   SELECT "RECORDID",
          "DAM_NAME",
          "OTHER_DAM_NAME",
          "DAM_FORMER_NAME",
          "STATEID",
          "NIDID",
          "LONGITUDE",
          "LATITUDE",
          "SECTION",
          "COUNTY",
          "RIVER",
          "CITY",
          "DISTANCE",
          "OWNER_NAME",
          "USACE_CRITICAL",
          "OWNER_TYPE",
          "DAM_DESIGNER",
          "PRIVATE_DAM",
          "DAM_TYPE",
          "CORE",
          "FOUNDATION",
          "PURPOSES",
          "YEAR_COMPLETED",
          "YEAR_MODIFIED",
          "DAM_LENGTH",
          "DAM_HEIGHT",
          "STRUCTURAL_HEIGHT",
          "HYDRAULIC_HEIGHT",
          "NID_HEIGHT",
          "MAX_DISCHARGE",
          "MAX_STORAGE",
          "NORMAL_STORAGE",
          "NID_STORAGE",
          "SURFACE_AREA",
          "DRAINAGE_AREA",
          "SORT_CATEGORY",
          "SHAPE"
     FROM CWMS_NID
/

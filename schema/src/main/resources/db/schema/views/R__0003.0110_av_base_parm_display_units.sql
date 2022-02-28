/**
 * Displays AV_BASE_PARM_DISPLAY_UNITS  information
 *
 * @since CWMS 3.0
 *
 * @field BASE_PARAMETER_CODE        The..
 * @field BASE_PARAMETER_ID          The..
 * @field UNIT_CODE                  The..
 * @field UNIT_ID                    The..
 * @field UNIT_SYSTEM                The..
 */
CREATE OR REPLACE FORCE VIEW AV_BASE_PARM_DISPLAY_UNITS
(
   BASE_PARAMETER_CODE,
   BASE_PARAMETER_ID,
   UNIT_CODE,
   UNIT_ID,
   UNIT_SYSTEM
)
AS
   SELECT cbp.base_parameter_code base_parameter_code,
          cbp.base_parameter_id base_parameter_id,
          cbp.display_unit_code_si unit_code,
          cu.unit_id unit_id,
          'SI' unit_system
     FROM cwms_base_parameter cbp, cwms_unit cu
    WHERE cbp.display_unit_code_si = cu.unit_code
   UNION
   SELECT cbp.base_parameter_code base_parameter_code,
          cbp.base_parameter_id base_parameter_id,
          cbp.display_unit_code_en unit_code,
          cu.unit_id unit_id,
          'EN' unit_system
     FROM cwms_base_parameter cbp, cwms_unit cu
    WHERE cbp.display_unit_code_en = cu.unit_code;
/

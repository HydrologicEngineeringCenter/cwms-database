insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_BASE_PARAMETER_UNITS', null,
'
/**
 * Displays AV_BASE_PARAMETER_UNITS information
 *
 * @since CWMS 2.1
 *
 * @field BASE_PARAMETER_ID          The..
 * @field UNIT_ID                    The..
 * @field IS_DB_BASE_UNIT            The..
 * @field ABSTRACT_PARAM_ID          The..
 * @field UNIT_SYSTEM                The..
 * @field OFFICE_ID                  The..
 * @field BASE_PARAMETER_CODE        The..
 * @field UNIT_CODE                  The..
 * @field DB_OFFICE_CODE             The..
 */
');
CREATE OR REPLACE FORCE VIEW AV_BASE_PARAMETER_UNITS
(
   BASE_PARAMETER_ID,
   UNIT_ID,
   IS_DB_BASE_UNIT,
   ABSTRACT_PARAM_ID,
   UNIT_SYSTEM,
   OFFICE_ID,
   BASE_PARAMETER_CODE,
   UNIT_CODE,
   DB_OFFICE_CODE
)
AS
   SELECT base_parameter_id,
          unit_id,
          CASE WHEN a.unit_code = b.unit_code THEN 'T' ELSE 'F' END
             IS_DB_BASE_UNIT,
          abstract_param_id,
          unit_system,
          db_office_id office_id,
          base_parameter_code,
          b.unit_code,
          db_office_code
     FROM cwms_base_parameter a JOIN av_unit b USING (abstract_param_code)
    WHERE unit_id IN (SELECT from_unit_id FROM cwms_unit_conversion)
/

grant select on av_base_parameter_units to cwms_user;

create or replace public synonym cwms_v_base_parameter_units for av_base_parameter_units;


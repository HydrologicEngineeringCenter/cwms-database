insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_GATE_RELEASE_REASON_CODE', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 3.0
 *
 * @field release_reason_code               The primary key for the reason c
 * @field db_office_code           		    The office code that owns the reason
 * @field release_reason_display_value      The short code (single character frequently) of the reason
 * @field release_reason_tooltip            The tooltip or description of the reason
 * @field release_reason_active             Active flag tf
 * @field db_office_id            			The DB Office 
 
');

CREATE OR REPLACE FORCE VIEW av_gate_Release_reason_code AS 
  SELECT rrc.release_reason_code
       , rrc.db_office_code
       , rrc.release_reason_display_value
       , rrc.release_reason_tooltip
       , rrc.release_reason_active
       , o.office_id db_Office_id
    FROM at_gate_Release_reason_code rrc
       , cwms_office o
   WHERE rrc.db_Office_code = o.office_code;
  
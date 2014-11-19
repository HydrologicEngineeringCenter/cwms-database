create type ztimeseries_type
/**
 * Object type representing time series values with attributes. This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 *
 * @member tsid CWMS time series identifier. This identifier includes six parts separated
 *         by the period (.) character:
 *         <ol>
 *         <li>location and optionally sub-location</li>
 *         <li>parameter and optionally sub-parameter</li>
 *         <li>parameter type</li>
 *         <li>interval (recurrance period)</li>
 *         <li>duration (coverage period)</li>
 *         <li>version</li>
 *         </ol>
 *
 * @member unit the unit of the value member of each record in the <code><big>data</big></code>
 *          member.
 *
 * @member data the time series values
 *
 * @see type ztsv_array
 */
AS OBJECT (
   tsid VARCHAR2 (183),
   unit VARCHAR2 (16),
   data ztsv_array);
/

   
create or replace public synonym cwms_t_ztimeseries for ztimeseries_type;


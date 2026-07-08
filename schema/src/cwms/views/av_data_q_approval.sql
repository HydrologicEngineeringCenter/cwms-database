insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_Q_APPROVAL', null,
'
/**
 * Displays information about the approval_id component of data quality codes
 *
 * @see view av_data_quality
 *
 * @field approval_id Specifies a valid value for the approval_id component
 * @field description Describes the specified value
 */
');
create view av_data_q_approval as select * from cwms_data_q_approval;

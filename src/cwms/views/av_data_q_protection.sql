insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_Q_PROTECTION', null,
'
/**
 * Displays information about the protection_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view av_data_quality
 *
 * @field protection_id Specifies a valid value for the protection_id component
 * @field description   Describes the specified value
 */
');
create view av_data_q_protection as select * from cwms_data_q_protection;

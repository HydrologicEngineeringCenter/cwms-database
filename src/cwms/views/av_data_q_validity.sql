insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_Q_VALIDITY', null,
'
/**
 * Displays information about the validity_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view av_data_quality
 *
 * @field validity_id  Specifies a valid value for the validity_id component
 * @field description  Describes the specified value
 */
');
create view av_data_q_validity as select * from cwms_data_q_validity;

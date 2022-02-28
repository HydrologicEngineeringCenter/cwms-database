/**
 * Displays information about the screened_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view av_data_quality
 *
 * @field screened_id  Specifies a valid value for the screened_id component
 * @field description  Describes the specified value
 */
create view av_data_q_screened as select * from cwms_data_q_screened;

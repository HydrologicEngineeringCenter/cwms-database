/**
 * Displays information about the changed_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view av_data_quality
 *
 * @field changed_id  Specifies a valid value for the changed_id component
 * @field description Describes the specified value
 */
create view av_data_q_changed as select * from cwms_data_q_changed;

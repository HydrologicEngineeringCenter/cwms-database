/**
 * Displays information about the repl_cause_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view av_data_quality
 *
 * @field repl_cause_id  Specifies a valid value for the repl_cause_id component
 * @field description    Describes the specified value
 */
create view av_data_q_repl_cause as select * from cwms_data_q_repl_cause;

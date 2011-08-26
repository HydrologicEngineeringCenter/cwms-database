insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_DATA_Q_REPL_CAUSE', null,
'
/**
 * Displays information about the repl_cause_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view mv_data_quality
 *
 * @field repl_cause_id  Specifies a valid value for the repl_cause_id component
 * @field description    Describes the specified value
 */
');
create materialized view mv_data_q_repl_cause as select * from cwms_data_q_repl_cause;

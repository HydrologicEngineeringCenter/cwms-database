insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_Q_REPL_METHOD', null,
'
/**
 * Displays information about the repl_method_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view mv_data_quality
 *
 * @field repl_method_id  Specifies a valid value for the repl_method_id component
 * @field description     Describes the specified value
 */
');
create view av_data_q_repl_method as select * from cwms_data_q_repl_method;

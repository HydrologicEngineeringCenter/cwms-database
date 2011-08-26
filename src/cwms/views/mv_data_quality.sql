insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_DATA_QUALITY', null,
'
/**
 * Displays information about data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view mv_data_q_screened
 * @see view mv_data_q_validity
 * @see view mv_data_q_range
 * @see view mv_data_q_changed
 * @see view mv_data_q_repl_cause
 * @see view mv_data_q_repl_method
 * @see view mv_data_q_test_failed
 * @see view mv_data_q_protection
 *
 * @field quality_code   The numeric data quality code
 * @field screened_id    Specifies whether the value has been screened
 * @field validity_id    Specifies the validity of the value
 * @field range_id       Specifies range encompasses the value
 * @field changed_id     Specifies whether the value was changed from its original state
 * @field repl_cause_id  Specifies why the value was changed, if it was
 * @field repl_method_id Specifies how the value was changed, if it was
 * @field test_failed_id Specifies which test(s), if any, were failed when the value was screened
 * @field protection_id  Specifies whether the value is protected from further change
 */
');
create materialized view mv_data_quality as select * from cwms_data_quality;

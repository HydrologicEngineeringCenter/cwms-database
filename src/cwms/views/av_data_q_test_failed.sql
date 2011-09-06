insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DATA_Q_TEST_FAILED', null,
'
/**
 * Displays information about the test_failed_id component of data quality codes
 *
 * @since CWMS 2.1
 *
 * @see view mv_data_quality
 *
 * @field test_failed_id  Specifies a valid value for the test_failed_id component
 * @field description     Describes the specified value
 */
');
create view av_data_q_test_failed as select * from cwms_data_q_test_failed;

/* Formatted on 7/8/2011 2:12:28 PM (QP5 v5.163.1008.3004) */
--
-- ZV_CURRENT_CRIT_FILE_CODE	(View)
--
--  Dependencies:
--   AT_SHEF_CRIT_FILE_REC (Table)
--

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/ZV_CURRENT_CRIT_FILE_CODE', null,
'
/**
 * [description needed]
 *
 * @since CWMS 2.1
 *
 * @see view mv_data_quality
 *
 * @field crit_file_code          [description needed]
 * @field data_stream_code        [description needed]
 * @field crit_file_creation_date [description needed]
 * @field num_decode_process_recs [description needed]
 * @field num_decode_ignore_recs  [description needed]
 * @field num_ignore_recs         [description needed]
 */
');
CREATE OR REPLACE FORCE VIEW zv_current_crit_file_code
(
	crit_file_code,
	data_stream_code,
	crit_file_creation_date,
	num_decode_process_recs,
	num_decode_ignore_recs,
	num_ignore_recs
)
AS
	SELECT	crit_file_code, data_stream_code, crit_file_creation_date,
				a.num_decode_process_recs, a.num_decode_ignore_recs,
				a.num_ignore_recs
	  FROM		at_shef_crit_file_rec a
				JOIN
					(SELECT		data_stream_code,
									MAX (a.crit_file_creation_date) crit_file_creation_date
						  FROM	at_shef_crit_file_rec a
					 GROUP BY	data_stream_code) b
				USING (data_stream_code, crit_file_creation_date)
/

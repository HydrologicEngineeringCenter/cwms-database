/* Formatted on 7/8/2011 2:11:35 PM (QP5 v5.163.1008.3004) */
--
-- AV_DATA_STREAMS  (View)
--
--  Dependencies:
--   AT_DATA_STREAM_ID (Table)
--   CWMS_OFFICE (Table)
--   AT_SHEF_CRIT_FILE_REC (Table)
--

CREATE OR REPLACE FORCE VIEW av_data_streams
(
	db_office_id,
	data_stream_id,
	data_stream_desc,
	ds_active_flag,
	crit_file_creation_date,
	num_decode_process_recs,
	num_decode_ignore_recs,
	num_spec_only_ignore_recs,
	total_ignore_recs,
	total_crit_file_recs,
	crit_file_code,
	data_stream_code,
	db_office_code
)
AS
	SELECT	  office_id db_office_id, data_stream_id, data_stream_desc,
				  active_flag ds_active_flag, crit_file_creation_date,
				  NVL (num_decode_process_recs, 0) num_decode_process_recs,
				  NVL (num_decode_ignore_recs, 0) num_decode_ignore_recs,
				  NVL (num_ignore_recs, 0) num_spec_only_ignore_recs,
				  NVL (num_decode_ignore_recs, 0) + NVL (num_ignore_recs, 0) total_ignore_recs,
				  NVL (num_decode_process_recs, 0) + NVL (num_decode_ignore_recs, 0) + NVL (num_ignore_recs, 0) total_crit_file_recs,
				  crit_file_code, data_stream_code, db_office_code
		 FROM   at_data_stream_id a
				  LEFT JOIN at_shef_crit_file_rec b
					  USING (data_stream_code)
				  JOIN cwms_office c
					  ON (a.db_office_code = c.office_code)
		WHERE   delete_date IS NULL
	ORDER BY   db_office_id,
				  UPPER (data_stream_id),
				  crit_file_creation_date DESC
/


--
-- CWMS_V_DATA_STREAMS  (Synonym) 
--
--  Dependencies: 
--   AV_DATA_STREAMS (View)
--
CREATE PUBLIC SYNONYM CWMS_V_DATA_STREAMS FOR AV_DATA_STREAMS
/


GRANT SELECT ON AV_DATA_STREAMS TO CWMS_USER
/

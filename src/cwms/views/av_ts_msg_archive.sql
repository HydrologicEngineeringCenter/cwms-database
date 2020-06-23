insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_MSG_ARCHIVE', null,
'
/**
 * Displays information about time series data store calls
 *
 * @since CWMS 18.1.3
 *
 * @field cwms_ts_id           Time series ID
 * @field db_office_id         Office ID of the time series
 * @field message_time         Time at which the data was requested to be stored
 * @field first_data_time      Starting date/time of this store call
 * @field last_data_time       End date/time of this store call
 */
');
create or replace force view av_ts_msg_archive (cwms_ts_id,
                db_office_id,
                message_time,
                first_data_time,
                last_data_time
) as
	SELECT cwms_ts_id,
       		db_office_id,
       		message_time,
       		first_data_time,
       		last_data_time
  	FROM (SELECT * FROM at_ts_msg_archive_1
        	UNION
        	SELECT * FROM at_ts_msg_archive_2) m,
       		at_cwms_ts_id  c
 		WHERE c.ts_code = m.TS_CODE;

grant select on av_ts_msg_archive to cwms_user;

create or replace public synonym cwms_v_ts_msg_archive for av_ts_msg_archive;


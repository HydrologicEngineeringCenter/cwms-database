drop package cwms_shef;

drop view av_active_flag;
drop view av_data_streams;
drop view av_data_streams_current;
drop view av_shef_decode_spec;
drop view av_shef_pe_codes;
drop view zv_current_crit_file_code;


drop table at_shef_decode;
drop table at_shef_ignore;
drop table at_shef_crit_file_rec;
drop table at_shef_spec_mapping_update;
drop table at_shef_decode_spec;
drop table at_shef_pe_codes;
drop table at_data_feed_id;
drop table at_data_stream_id;
drop table at_data_stream_properties;
drop table cwms_shef_extremum_codes;
drop table cwms_shef_pe_codes;
drop table cwms_shef_time_zone;

drop type shef_spec_type force;
drop type shef_spec_array force;

drop public synonym cwms_t_shef_spec;
drop public synonym cwms_t_shef_spec_array;
drop public synonym cwms_v_shef_decode_spec;
drop public synonym cwms_v_shef_pe_codes;
drop public synonym cwms_shef;
drop public synonym cwms_v_active_flag;
drop public synonym cwms_v_data_streams;
drop public synonym cwms_v_data_streams_current;

delete
  from cwms_auth_sched_entries
 where job_name = 'UPDATE_SHEF_SPEC_MAPPING';

delete
  from at_clob
 where id in ('/VIEWDOCS/AV_ACTIVE_FLAG',
              '/VIEWDOCS/AV_DATA_STREAMS',
              '/VIEWDOCS/AV_DATA_STREAMS_CURRENT',
              '/VIEWDOCS/AV_SHEF_DECODE_SPEC',
              '/VIEWDOCS/AV_SHEF_PE_CODES',
              '/VIEWDOCS/ZV_CURRENT_CRIT_FILE_CODE'
             );


from __future__      import with_statement
import os, string, StringIO

at_tables = {
#  table name           office column name
#  ------------------   -------------------
   'at_parameter'     : 'db_office_code',
   'at_display_units' : 'db_office_code',
   'at_location_kind' : 'office_code'
}

cwms_tables = [
   'cwms_apex_roles',
   'cwms_base_parameter',
   'cwms_county',
   'cwms_data_q_changed',
   'cwms_data_q_protection',
   'cwms_data_q_range',
   'cwms_data_q_repl_cause',
   'cwms_data_q_repl_method',
   'cwms_data_q_screened',
   'cwms_data_q_test_failed',
   'cwms_data_q_validity',
   'cwms_dss_parameter_type',
   'cwms_dss_xchg_direction',
   'cwms_duration',
   'cwms_error',
   'cwms_gage_method',
   'cwms_gage_type',
   'cwms_interpolate_units',
   'cwms_interval',
   'cwms_interval_offset',
   'cwms_log_message_prop_types',
   'cwms_log_message_types',
   'cwms_msg_id',
   'cwms_nation',
   'cwms_office',
   'cwms_parameter_type',
   'cwms_rating_method',
   'cwms_schema_object_version',
   'cwms_sec_privileges',
   'cwms_sec_ts_groups',
   'cwms_sec_user_groups',
   'cwms_shef_duration',
   'cwms_shef_extremum_codes',
   'cwms_shef_pe_codes',
   'cwms_shef_time_zone',
   'cwms_state',
   'cwms_stream_type',
   'cwms_time_zone',
   'cwms_time_zone_alias',
   'cwms_tr_transformations',
   'cwms_tz_usage',
   'cwms_unit',
   'cwms_unit_conversion'
]

def get_static_data(filename) :
   f = StringIO.StringIO()
   f.write('set linesize 2000\nset pagesize 1000\nspool %s\n' % filename)
   for table_name in at_tables.keys() :
      f.write('prompt .\nprompt table %s\n' % table_name)
      f.write('select * from %s where %s = 53;\n' % (table_name, at_tables[table_name]))
   for table_name in cwms_tables :
      f.write('prompt .\nprompt table %s\n' % table_name)
      f.write('select * from %s;\n' % table_name)
   f.write('spool off\n')
   buf = f.getvalue()
   f.close()
   return buf

def trim_data_file(filename) :
   with open(filename, 'r') as f : lines = f.read().split('\n')
   with open(filename, 'w') as f : f.write('\n'.join(map(string.rstrip, lines)))

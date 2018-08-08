import os, re, sys

pkg_pattern     = re.compile(r'create(\s+or\s+replace)?\s+package', re.I)
type_pattern1   = re.compile(r'create(\s+or\s+replace)?\s+type\s+(\w+)\s+(\S+)', re.I)
type_pattern2   = re.compile(r'create(\s+or\s+replace)?\s+type', re.I)
exec_pattern    = re.compile(r'^/\s*$', re.M)
view_pattern1   = re.compile(r"'\s*/\*{2}.+\*/\s*'", re.S)
view_pattern2   = re.compile(r'(create(\s+or\s+replace(\s+force)?)?)\s+view\s+.+$', re.I | re.S)
commit_pattern  = re.compile(r'^\s*commit\s*$', re.I | re.M)
defines_pattern = re.compile('@@defines.sql', re.I)

synonyms = {}
updates  = [
	['script',       'updateScripts/pre_compile'],
	['script',       'updateScripts/at_a2w_updates'],
        ['script',       'updateScripts/updateUSGSTable'],
        ['script',       'updateScripts/db_change_log_update'],
        ['package spec', 'cwms_alarm'],
        ['package body', 'cwms_alarm'],
        ['package body', 'cwms_apex'],
        ['package spec', 'cwms_basin'],
        ['package body', 'cwms_basin'],
        ['package spec', 'cwms_cat'],
        ['package body', 'cwms_cat'],
        ['package spec', 'cwms_cma'],
        ['package body', 'cwms_cma'],
        ['package spec', 'cwms_db_chg_log'],
        ['package body', 'cwms_db_chg_log'],
        ['package body', 'cwms_display'],
        ['package spec', 'cwms_embank'],
        ['package body', 'cwms_embank'],
        ['package spec', 'cwms_env'],
        ['package body', 'cwms_env'],
        ['package body', 'cwms_forecast'],
        ['package body', 'cwms_gage'],
        ['package spec', 'cwms_level'],
        ['package body', 'cwms_level'],
        ['package spec', 'cwms_loc'],
        ['package body', 'cwms_loc'],
        ['package spec', 'cwms_lock'],
        ['package body', 'cwms_lock'],
        ['package body', 'cwms_lookup'],
        ['package spec', 'cwms_mail'],
        ['package body', 'cwms_mail'],
        ['package body', 'cwms_msg'],
        ['package spec', 'cwms_outlet'],
        ['package body', 'cwms_outlet'],
        ['package body', 'cwms_priv'],
        ['package spec', 'cwms_project'],
        ['package body', 'cwms_project'],
        ['package body', 'cwms_prop'],
        ['package spec', 'cwms_rating'],
        ['package body', 'cwms_rating'],
        ['package spec', 'cwms_rounding'],
        ['package body', 'cwms_rounding'],
        ['package spec', 'cwms_sec'],
        ['package body', 'cwms_sec'],
        ['package body', 'cwms_shef'],
        ['package spec', 'cwms_stream'],
        ['package body', 'cwms_stream'],
        ['package spec', 'cwms_text'],
        ['package body', 'cwms_text'],
        ['package spec', 'cwms_ts'],
        ['package body', 'cwms_ts'],
        ['package body', 'cwms_ts_id'],
        ['package spec', 'cwms_turbine'],
        ['package body', 'cwms_turbine'],
        ['package body', 'cwms_upass'],
        ['package spec', 'cwms_usgs'],
        ['package body', 'cwms_usgs'],
        ['package spec', 'cwms_util'],
        ['package body', 'cwms_util'],
        ['package body', 'cwms_vt'],
        ['package body', 'cwms_water_supply'],
        ['package spec', 'cwms_xchg'],
        ['package body', 'cwms_xchg'],
        ['type',         'anydata_tab_t'],
        ['type',         'abs_logic_expr_t'],
        ['type body',    'abs_logic_expr_t'],
        ['type',         'abs_rating_ind_param_t'],
        ['type body',    'abs_rating_ind_param_t'],
        ['type',         'gate_change_obj_t'],
        ['type',         'gate_setting_obj_t'],
        ['type',         'loc_lvl_cur_max_ind_tab_t'],
        ['type',         'loc_lvl_indicator_t'],
        ['type body',    'loc_lvl_indicator_t'],
        ['type',         'loc_lvl_indicator_cond_t'],
        ['type body',    'loc_lvl_indicator_cond_t'],
        ['type',         'location_obj_t'],
        ['type body',    'location_obj_t'],
        ['type body',    'location_ref_t'],
        ['type',         'logic_expr_t'],
        ['type body',    'logic_expr_t'],
        ['type',         'rating_conn_map_t'],
        ['type',         'rating_conn_map_tab_t'],
        ['type',         'rating_ind_parameter_t'],
        ['type body',    'rating_ind_parameter_t'],
        ['type',         'rating_t'],
        ['type body',    'rating_t'],
        ['type',         'rating_tab_t'],
        ['type body',    'seasonal_value_t'],
        ['type',         'stream_rating_t'],
        ['type body',    'stream_rating_t'],
        ['type',         'streamflow_meas_t'],
        ['type body',    'streamflow_meas_t'],
        ['type',         'tsv_array'],
        ['type',         'tsv_array_tab'],
        ['type',         'vdatum_rating_t'],
        ['type body',    'vdatum_rating_t'],
        ['type',         'vdatum_stream_rating_t'],
        ['type body',    'vdatum_stream_rating_t'],
        ['type',         'vert_datum_offset_t'],
        ['type',         'vert_datum_offset_tab_t'],
        ['type',         'ztsv_array_tab'],
        ['type',         'cat_county_obj_t'],
        ['type',         'cat_county_otab_t'],
        ['type',         'cat_dss_file_obj_t'],
        ['type',         'cat_dss_file_otab_t'],
        ['type',         'cat_dss_xchg_set_obj_t'],
        ['type',         'cat_dss_xchg_set_otab_t'],
        ['type',         'cat_dss_xchg_ts_map_obj_t'],
        ['type',         'cat_location2_obj_t'],
        ['type',         'cat_location2_otab_t'],
        ['type',         'cat_location_kind_obj_t'],
        ['type',         'cat_location_kind_otab_t'],
        ['type',         'cat_location_obj_t'],
        ['type',         'cat_location_otab_t'],
        ['type',         'cat_loc_alias_obj_t'],
        ['type',         'cat_loc_alias_otab_t'],
        ['type',         'cat_loc_obj_t'],
        ['type',         'cat_loc_otab_t'],
        ['type',         'cat_param_obj_t'],
        ['type',         'cat_param_otab_t'],
        ['type',         'cat_state_obj_t'],
        ['type',         'cat_state_otab_t'],
        ['type',         'cat_sub_loc_obj_t'],
        ['type',         'cat_sub_loc_otab_t'],
        ['type',         'cat_sub_param_obj_t'],
        ['type',         'cat_sub_param_otab_t'],
        ['type',         'cat_timezone_obj_t'],
        ['type',         'cat_timezone_otab_t'],
        ['type',         'cat_ts_cwms_20_obj_t'],
        ['type',         'cat_ts_cwms_20_otab_t'],
        ['type',         'cat_ts_obj_t'],
        ['type',         'cat_ts_otab_t'],
        ['type',         'jms_map_msg_tab_t'],
        ['type',         'logic_expr_tab_t'],
        ['type',         'seasonal_location_level_t'],
        ['type',         'seasonal_loc_lvl_tab_t'],
        ['type',         'seasonal_value_tab_t'],
        ['type',         'source_type'],
        ['type',         'turbine_setting_obj_t'],
        ['type',         'cat_dss_xchg_tsmap_otab_t'],
        ['type',         'source_array'],
        ['type',         'zloc_lvl_indicator_t'],
        ['type body',    'zloc_lvl_indicator_t'],
        ['type',         'zloc_lvl_indicator_tab_t'],
        ['type',         'loc_type_ds'],
        ['type',         'nested_ts_type'],
        ['type',         'zlocation_level_t'],
        ['type body',    'zlocation_level_t'],
        ['type',         'nested_ts_table'],
	['type',         'xml_tab_t'],
	['type',         'streamflow_meas_t'],
	['type body',    'streamflow_meas_t'],
	['type',         'streamflow_meas_tab_t'],
	['type',         'stream_t'],
	['type body',    'stream_t'],
	['type',         'stream_tab_t'],
        ['view',         'av_a2w_ts_codes_by_loc'],
        ['view',         'av_db_change_log'],
        ['view',         'av_compound_outlet'],
        ['view',         'av_gage'],
        ['view',         'av_gage_method'],
        ['view',         'av_gage_sensor'],
        ['view',         'av_gage_type'],
        ['view',         'av_location_level'],
        ['view',         'av_location_kind'],
        ['view',         'av_loc'],
        ['view',         'av_loc2'],
        ['view',         'av_lock'],
        ['view',         'av_outlet'],
        ['view',         'av_rating'],
        ['view',         'av_rating_local'],
        ['view',         'av_rating_spec'],
        ['view',         'av_rating_template'],
        ['view',         'av_streamflow_meas'],
        ['view',         'av_text_filter'],
        ['view',         'av_transitional_rating'],
        ['view',         'av_vert_datum_offset'],
        ['view',         'av_virtual_rating'],
        ['view',         'av_usgs_parameter'],
        ['view',         'av_usgs_rating'],
	['script',       'cwms/views/av_sec_users'],
	['script',       'cwms/at_schema_env'],
	['script',       'cwms/at_schema_public_interface'],
	['script',       'compileAll'],
	['script',       'updateScripts/post_compile'],
	['script',       'compileAll'],
	['script',       'cwms_version']
]

srcdir = os.path.join(os.path.split(sys.argv[0])[0], 'cwms')

def get(item_type, item_name) :
	try    : main_type, sub_type = item_type.split()
	except : main_type, sub_type = item_type, ''
	if main_type == 'package' :
		if sub_type == 'spec' :
			filename = os.path.join(srcdir, '%s_pkg.sql' % item_name)
		elif sub_type == 'body' :
			filename = os.path.join(srcdir, '%s_pkg_body.sql' % item_name)
		else :
			raise Exception('Invalid item type: "%s"' % item_type)
		f = open(filename)
		text = f.read()
		f.close()
		return pkg_pattern.sub('create or replace package', text)
	elif main_type == 'type' :
		if sub_type == '' :
			filename = os.path.join(srcdir, 'types/%s.sql' % item_name)
		elif sub_type == 'body' :
			filename = os.path.join(srcdir, 'types/%s-body.sql' % item_name)
		else :
			raise Exception('Invalid item type: "%s"' % item_type)
		f = open(filename)
		text = f.read()
		f.close()
		if not sub_type :
			str = ('whenever sqlerror continue\ndrop type %s force;\nwhenever sqlerror exit sql.sqlcode\n%s' % (
				item_name, type_pattern2.sub('create type', text)))
		else :
			str = type_pattern2.sub('create or replace type', text)
		return str
	elif main_type == 'view' :
		filename = os.path.join(srcdir, 'views', '%s.sql' % item_name.lower())
		f = open(filename)
		text = f.read()
		f.close()
		clob_id = '/VIEWDOCS/%s' % item_name.upper()
		match = view_pattern1.search(text)
		clob_update = ''
		if match is not None:
			match_end = match.end(0)
			javadoc = match.group(0)
			clob_update = "update at_clob set value=%s where office_code = 53 and id = '%s';" % (javadoc, clob_id)
		else:
			match_end = 0
		match = view_pattern2.search(text[match_end:])
		view_update = match.group(0).replace(match.group(1), 'create or replace force ')
		return "%s\n%s" % (clob_update, view_update)
	elif main_type == 'script':
		filename = os.path.join('%s.sql' % item_name)
		f = open(filename)
		text = f.read()
		f.close()
		return text
	else :
		raise Exception('Invalid item type: "%s"' % item_type)

outfile = os.path.join('.', 'updateCwmsSchema30.sql')
logfile = 'updateCwmsSchema30.log'
f = open(outfile, 'w')
f.write(
'''
define cwms_schema = CWMS_20
set define on
set verify off
whenever sqlerror exit sql.sqlcode
''')
f.write('\nspool '+logfile+'; \n')
for item_type, item_name in updates :
	print('%s %s' % (item_type, item_name))
	item_text = get(item_type, item_name)
	item_text = commit_pattern.sub('commit;', item_text)
	item_text = defines_pattern.sub('', item_text)
	f.write('set define on\ndefine cwms_schema = CWMS_20\n')
	message = 'update for %s %s' % (item_type, item_name)
	f.write('prompt %s\n%s\n' % (message, item_text))
	if item_type == 'view' :
		f.write('whenever sqlerror continue\n')
		f.write('drop public synonym %s;\n' % item_name.replace('av_', 'cwms_v_'))
		f.write('whenever sqlerror exit sql.sqlcode\n')
		f.write('create public synonym %s for &cwms_schema..%s;\n' % (item_name.replace('av_', 'cwms_v_'), item_name))
f.write('\ncommit;\n\n')
f.write('\nexit;\n\n')
f.close()
print('\nUpdate script is %s' % outfile)

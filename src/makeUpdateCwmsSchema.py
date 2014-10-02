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
	['script',       'updateScript_pre_compile'],
        ['package spec', 'cwms_alarm'],
        ['package body', 'cwms_alarm'],
        ['package body', 'cwms_apex'],
        ['package spec', 'cwms_basin'],
        ['package body', 'cwms_basin'],
        ['package spec', 'cwms_cat'],
        ['package body', 'cwms_cat'],
        ['package body', 'cwms_display'],
        ['package spec', 'cwms_embank'],
        ['package body', 'cwms_embank'],
        ['package spec', 'cwms_env'],
        ['package body', 'cwms_env'],
        ['package body', 'cwms_forecast'],
        ['package body', 'cwms_gage'],
        ['package body', 'cwms_level'],
        ['package spec', 'cwms_loc'],
        ['package body', 'cwms_loc'],
        ['package spec', 'cwms_lock'],
        ['package body', 'cwms_lock'],
        ['package body', 'cwms_msg'],
        ['package spec', 'cwms_outlet'],
        ['package body', 'cwms_outlet'],
        ['package body', 'cwms_priv'],
        ['package spec', 'cwms_project'],
        ['package body', 'cwms_project'],
        ['package body', 'cwms_prop'],
        ['package spec', 'cwms_rating'],
        ['package body', 'cwms_rating'],
        ['package spec', 'cwms_schema'],
        ['package body', 'cwms_schema'],
        ['package spec', 'cwms_sec'],
        ['package body', 'cwms_sec'],
        ['package body', 'cwms_shef'],
        ['package spec', 'cwms_stream'],
        ['package body', 'cwms_stream'],
        ['package spec', 'cwms_text'],
        ['package body', 'cwms_text'],
        ['package body', 'cwms_ts'],
        ['package body', 'cwms_ts_id'],
        ['package spec', 'cwms_turbine'],
        ['package body', 'cwms_turbine'],
        ['package spec', 'cwms_usgs'],
        ['package body', 'cwms_usgs'],
        ['package spec', 'cwms_util'],
        ['package body', 'cwms_util'],
        ['package body', 'cwms_vt'],
        ['package body', 'cwms_water_supply'],
        ['package spec', 'cwms_xchg'],
        ['package body', 'cwms_xchg'],
        ['type',         'abs_rating_ind_param_t'],
        ['type body',    'abs_rating_ind_param_t'],
        ['type',         'loc_lvl_cur_max_ind_tab_t'],
        ['type body',    'loc_lvl_indicator_t'],
        ['type body',    'loc_lvl_indicator_cond_t'],
        ['type body',    'location_obj_t'],
        ['type body',    'location_ref_t'],
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
        ['type',         'tsv_array'],
        ['type',         'tsv_array_tab'],
        ['type',         'vdatum_rating_t'],
        ['type body',    'vdatum_rating_t'],
        ['type',         'vdatum_stream_rating_t'],
        ['type body',    'vdatum_stream_rating_t'],
        ['type',         'vert_datum_offset_t'],
        ['type',         'vert_datum_offset_tab_t'],
        ['type',         'ztsv_array_tab'],
        ['view',         'av_location_kind'],
        ['view',         'av_loc'],
        ['view',         'av_loc2'],
        ['view',         'av_outlet'],
        ['view',         'av_vert_datum_offset'],
        ['view',         'av_virtual_rating'],
        ['view',         'av_usgs_parameter'],
        ['view',         'av_usgs_rating'],
	['script',       'cwms/views/av_sec_users'],
	['script',       'cwms/at_schema_env'],
	['script',       'cwms/at_schema_public_interface'],
	['script',       'compileAll'],
	['script',       'updateScript_post_compile'],
	['script',       'compileAll'],
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
		if item_name.lower().find('rating') == -1 :
			filename = (os.path.join(srcdir, 'cwms_types.sql'))
		else :
			filename = (os.path.join(srcdir, 'cwms_types_rating.sql'))
		f = open(filename)
		text = f.read()
		f.close()
		matches = type_pattern1.finditer(text)
		match = matches.next()
		type_list = []
		while True :
			type_name = match.group(2)
			if type_name in ('spec', 'body') :
				type_type = type_name
				type_name = match.group(3)
			else :
				type_type = ''
			start = match.start(0)
			type_list.append(['%s %s' % (type_name, type_type), start, -1])
			try    : match = matches.next()
			except : break
		for i in range(len(type_list)-1) :
			type_list[i][2] = type_list[i+1][1]
		types = {}
		for i in range(len(type_list)) :
			type_info, start, end = type_list[i]
			matcher = exec_pattern.search(text[start:end])
			if matcher : end = start + matcher.end()
			types[type_info] = [start, end]
		start, end = types['%s %s' % (item_name, sub_type)]
		if not sub_type :
			str = ('whenever sqlerror continue\ndrop type %s force;\nwhenever sqlerror exit sql.sqlcode\n%s' % (
				item_name, type_pattern2.sub('create type', text[start:end])))
		else :
			str = type_pattern2.sub('create or replace type', text[start:end])
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

outfile = os.path.join('.', 'updateCwmsSchema.sql')
logfile = 'updateCwmsSchema.log'
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
f.close()
print('\nUpdate script is %s' % outfile)

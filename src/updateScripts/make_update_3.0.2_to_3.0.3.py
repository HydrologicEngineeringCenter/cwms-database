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
        ['package spec', 'cwms_env'],
        ['package body', 'cwms_env'],
        ['package spec', 'cwms_sec'],
        ['package body', 'cwms_sec'],
        ['package spec', 'cwms_ts'],
        ['package body', 'cwms_ts'],
        ['package body', 'cwms_text'],
        ['package spec', 'cwms_util'],
        ['package body', 'cwms_util'],
        ['package spec', 'cwms_sec'],
        ['package body', 'cwms_sec'],
        ['package spec', 'cwms_upass'],
        ['package body', 'cwms_upass'],
        ['view'        , 'av_usgs_agency'],
        ['view'        , 'av_base_parm_display_units'],
        ['view'        , 'av_screening_control'],
        ['view'        , 'av_screening_criteria'],
        ['view'        , 'av_screening_dur_mag'],
	['script',       '../compileAll'],
	['script',       'create_logon_triggers'],
	['script',       '3_0_3_Updates'],
	['script',       '../cwms/create_sec_triggers'],
	['script',       '../cwms_version']
]

srcdir = os.path.join(os.path.split(sys.argv[0])[0], '../cwms')

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

outfile = os.path.join('.', 'update_3.0.2_to_3.0.3.sql')
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

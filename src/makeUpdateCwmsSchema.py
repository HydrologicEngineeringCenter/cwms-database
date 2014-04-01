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
	['script',       'stop_all_jobs'],
	['package spec', 'cwms_alarm'],
	['package body', 'cwms_alarm'],
	['package spec', 'cwms_env'],
	['package body', 'cwms_env'],
	['package body', 'cwms_level'],
	['package spec', 'cwms_loc'],
	['package body', 'cwms_loc'],
	['package spec', 'cwms_msg'],
	['package body', 'cwms_msg'],
	['package spec', 'cwms_rating'],
	['package body', 'cwms_rating'],
	['package spec', 'cwms_schema'],
	['package spec', 'cwms_sec'],
	['package body', 'cwms_sec'],
	['package body', 'cwms_ts'],
	['package spec', 'cwms_upass'],
	['package body', 'cwms_upass'],
	['package spec', 'cwms_util'],
	['package body', 'cwms_util'],
	['type',         'abs_rating_ind_param_t'],
	['type body',    'abs_rating_ind_param_t'],
	['type',         'loc_lvl_cur_max_ind_tab_t'],
	['type',         'loc_lvl_indicator_cond_t'],
	['type body',    'loc_lvl_indicator_cond_t'],
	['type',         'rating_ind_parameter_t'],
	['type body',    'rating_ind_parameter_t'],
	['type',         'rating_t'],
	['type body',    'rating_t'],
	['type',         'stream_rating_t'],
	['type body',    'stream_rating_t'],
	['view',         'av_sec_users'],
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

outfile = os.path.join(srcdir, 'updateCwmsSchema.sql')
logfile = 'updateCwmsSchema.log'
f = open(outfile, 'w')
f.write('\nspool '+logfile+'; \n')
f.write('''
create table at_vert_datum_offset (
   location_code       number(10)    not null,
   vertical_datum_id_1 varchar2(16)  not null,
   vertical_datum_id_2 varchar2(16)  not null,
   effective_date      date          default date '1000-01-01',
   offset              binary_double not null,
   description         varchar2(64),
   constraint at_vert_datum_offset_pk  primary key (location_code, vertical_datum_id_1, vertical_datum_id_2, effective_date),
   constraint at_vert_datum_offset_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_vert_datum_offset_fk2 foreign key (vertical_datum_id_1) references cwms_vertical_datum (vertical_datum_id),
   constraint at_vert_datum_offset_fk3 foreign key (vertical_datum_id_2) references cwms_vertical_datum (vertical_datum_id),
   constraint at_vert_datum_offset_ck1 check (vertical_datum_id_1 <> vertical_datum_id_2)
) tablespace cwms_20at_data
/

comment on table  at_vert_datum_offset                     is 'Contains vertical datum offsets for CWMS locations';
comment on column at_vert_datum_offset.location_code       is 'References CWMS location';
comment on column at_vert_datum_offset.vertical_datum_id_1 is 'References vertical datum for input';
comment on column at_vert_datum_offset.vertical_datum_id_2 is 'References vertical datum for output';
comment on column at_vert_datum_offset.effective_date      is 'Earliest date/time the offset if in effect';
comment on column at_vert_datum_offset.offset              is 'Value added to input to generate output';
comment on column at_vert_datum_offset.description         is 'Description or comment';

create table at_vert_datum_local (
   location_code    number(10),
   local_datum_name varchar2(16) not null,
   constraint at_vert_datum_local_pk  primary key (location_code) using index,
   constraint at_vert_datum_local_fk1 foreign key (location_code) references at_physical_location(location_code)
) tablespace cwms_20at_data
/

comment on table  at_vert_datum_local                  is 'Contains names of local vertical datums for locations.';
comment on column at_vert_datum_local.location_code    is 'References location with a named local vertical datum.';
comment on column at_vert_datum_local.local_datum_name is 'Name of local vertical datum for location.';
''')
for item_type, item_name in updates :
	print('%s %s' % (item_type, item_name))
	item_text = get(item_type, item_name)
	item_text = commit_pattern.sub('commit;', item_text)
	item_text = defines_pattern.sub('', item_text)
	f.write('set define on\ndefine cwms_schema = CWMS_20\n')
	message = 'update for %s %s' % (item_type, item_name)
	f.write('prompt %s\n%s\n' % (message, item_text))
	if item_type == 'view' :
		synonyms[item_name] = item_name.replace('av_', 'cwms_v_')
f.write('\ncommit;\n\n')
if synonyms :
	f.write('whenever sqlerror continue\n')
	for synonym in sorted(synonyms.values()) :
		f.write('drop public synonym %s;\n' % synonym)
	f.write('whenever sqlerror exit sql.sqlcode\n')
	for view in sorted(synonyms.keys()) :
		f.write('create public synonym %s for &cwms_schema..%s;\n' % (synonyms[view], view))
f.write('\ncommit;\n')
f.write(
'''
whenever sqlerror continue
ALTER TABLE AT_SEC_USERS DROP CONSTRAINT AT_SEC_USERS_R02;
 
ALTER TABLE AT_SEC_USERS ADD (
  CONSTRAINT AT_SEC_USERS_R02 
  FOREIGN KEY (USERNAME) 
  REFERENCES AT_SEC_CWMS_USERS (USERID)
  ENABLE VALIDATE);
/  
''');
f.write(
'''
set echo off
set define on
whenever sqlerror exit sql.sqlcode
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
exec sys.utl_recomp.recomp_serial('&cwms_schema');
/

prompt Remaining invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

declare
   obj_count integer;
begin
   select count(*)
     into obj_count
     from dba_objects
    where owner = '&cwms_schema'
      and status = 'INVALID';
   if obj_count > 0 then
      dbms_output.put_line('' || obj_count || ' objects are still invalid.');
      raise_application_error(-20999, 'Some objects are still invalid.');
   else
      dbms_output.put_line('All invalid objects successfully compiled.');
   end if;
end;
/
''')
f.close()
print('\nUpdate script is %s' % outfile)

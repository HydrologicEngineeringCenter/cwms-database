import os, re, sys

class version_info :
	def __init__(self, application, version, version_date, title, description) :
		self.application  = application
		self.version      = version
		self.version_date = version_date
		self.title        = title
		self.description  = description
		self.major, self.minor, self.build = self.version.split(".")
		
before_update_version = version_info(
	"CWMS",
	"3.0.1",
	"04SEP2015",
	"CWMS Database Release 3.0.1",
	"\n".join([
		"Added some new unit conversions.",
		"Added some views for upward reporting.",
		"Updated CMA support to version 2.02.",
		"Added capability to send e-mail from database routines.",
		"Added database schema versioning.",
		"Various bug fixes and minor API improvements."]))

after_update = version_info(
	"CWMS",
	"3.0.2",
	"21OCT2015",
	"CWMS Database 3.0.2",
	"\n".join([
		"Fixed bug where some routines consumed excessive amounts of sequence values.",
		"Changed to allow multiple stream locations to share the same station on a stream",
		"Various other fixes."]))
	
prolog = \
'''
set define off
----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
whenever sqlerror exit sql.sqlcode
begin
   for rec in 
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from av_db_change_log
        where version_date = (select max(version_date) from av_db_change_log)
      )
   loop
      if rec.version != '%s' or rec.version_date != '%s' then
      	cwms_err.raise('ERROR', 'Expected version %s (%s), got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/
whenever sqlerror continue
''' % (before_update_version.version,
       before_update_version.version_date,
       before_update_version.version,
       before_update_version.version_date)

epilog = \
'''
--------------------
-- update version --
--------------------
insert 
  into cwms_db_change_log                                                     
       (application,
        ver_major,
        ver_minor,
        ver_build,
        ver_date,
        title,
        description
       )
values ('%s', 
         %s,
         %s,
         %s,
         to_date ('%s', 'DDMONYYYY'),
        '%s',
        '%s'
       );
commit;
---------------------------------------
-- recompile schema and check erorrs --
---------------------------------------
exec sys.utl_recomp.recomp_serial('CWMS_20');
/

select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
 from dba_objects 
where owner = 'CWMS_20' 
  and status = 'INVALID'
order by object_name, object_type asc;

select type,
       name, 
       line, 
       position, 
       text 
  from user_errors
 where attribute='ERROR' 
 order by 2,3,4; 

''' % (after_update.application,
       after_update.major,
       after_update.minor,
       after_update.build,
       after_update.version_date,
       after_update.title,
       after_update.description)


header_pattern_template = "(-+\s+--(?:New|Changed) %s\s+--(?:\w|\$)+\s+-+)"
obj_name_pattern_template = "-+\s+--(?:New|Changed) %s\s+--((\w|\$)+)\s+-+"

script_dir = sys.argv[1]

def get_headers(file_name, data_type) :
	header_pattern = re.compile(header_pattern_template % data_type)
	name_pattern = re.compile(obj_name_pattern_template % data_type)
	with open(file_name, 'r') as f : data = f.read().strip()
	headers = header_pattern.findall(data)
	return headers, name_pattern, data
	
update_file         = os.path.join(script_dir, "UPDATE.sql")
ignore_file         = os.path.join(script_dir, "IGNORE.sql")
tables_file         = os.path.join(script_dir, "TABLES.sql")
indexes_file        = os.path.join(script_dir, "INDEXES.sql")
types_file          = os.path.join(script_dir, "TYPES.sql")
packages_file       = os.path.join(script_dir, "PACKAGES.sql")
procedures_file     = os.path.join(script_dir, "PROCEDURES.sql")
functions_file      = os.path.join(script_dir, "FUNCTIONS.sql")
views_file          = os.path.join(script_dir, "VIEWS.sql")
type_bodies_file    = os.path.join(script_dir, "TYPE_BODIES.sql")
package_bodies_file = os.path.join(script_dir, "PACKAGE_BODIES.sql")

#---------------------------------------#
# split the types into specs and bodies #
#---------------------------------------#
if os.path.exists(types_file) :
	headers, name_pattern, data = get_headers(types_file, "TYPE")
	parts = os.path.splitext(types_file)
	types_file = parts[0]+"_"+parts[1]
	spec_f = open(types_file, 'w')
	body_f = open(type_bodies_file, 'w')
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			type_name = name_pattern.match(headers[i]).group(1)
			body_pos = sql.find("CREATE OR REPLACE TYPE BODY")
			if body_pos == -1:
				spec = sql
				body = None
			else :
				spec = sql[:body_pos]
				body = sql[body_pos:]
			#-------------------------------------------------------------------#
			# "CREATE OR REPLACE" won't work on existing type with dependencies #
			#-------------------------------------------------------------------#
			spec = spec.replace(
				'CREATE OR REPLACE TYPE "%s"' % type_name, 
				'DROP TYPE "%s" FORCE;\nCREATE TYPE "%s"' % (type_name, type_name))			
			if not spec.startswith("Unable to compare objects.") : spec += "/\n"
			spec_f.write("%s\n%s\n" % (headers[i], spec))
			if body :
				lines = headers[i].split("\n")
				lines[1] += " BODY"
				body_f.write("%s\n%s\n" % ("\n".join(lines), body))
	spec_f.close()
	body_f.close()

update_f = open(update_file, 'w')
ignore_f = open(ignore_file, 'w')
update_f.write(prolog)
#--------#
# TABLES #
#--------#
if os.path.exists(tables_file) :
	headers, name_pattern, data = get_headers(tables_file, "TABLE")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			table_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif table_name.startswith("AT_") : 
				f = update_f
			elif table_name.startswith("CWMS_") : 
				f = update_f
			else : 
				f = ignore_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#---------#
# INDEXES #
#---------#
if os.path.exists(indexes_file) :
	headers, name_pattern, data = get_headers(indexes_file, "INDEX")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			index_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif index_name.startswith("AT_") : 
				f = update_f
			elif index_name.startswith("CWMS_") : 
				f = update_f
			else : 
				f = ignore_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#------------#
# TYPE SPECS #
#------------#
if os.path.exists(types_file) :
	headers, name_pattern, data = get_headers(types_file, "TYPE")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			type_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif type_name.startswith("SYS_") : 
				f = ignore_f
			elif "$" in type_name : 
				f = ignore_f
			else : 
				f = update_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#---------------#
# PACKAGE SPECS #
#---------------#
if os.path.exists(packages_file) :
	headers, name_pattern, data = get_headers(packages_file, "PACKAGE")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			package_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif package_name.startswith("CWMS_") : 
				f = update_f
			else : 
				f = ignore_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#------------#
# PROCEDURES #
#------------#
if os.path.exists(procedures_file) :
	headers, name_pattern, data = get_headers(procedures_file, "PROCEDURE")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			procedure_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			else : 
				f = update_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#-----------#
# FUNCTIONS #
#-----------#
if os.path.exists(functions_file) :
	headers, name_pattern, data = get_headers(functions_file, "FUNCTION")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			function_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			else : 
				f = update_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#-------#
# VIEWS #
#-------#
if os.path.exists(views_file) :
	headers, name_pattern, data = get_headers(views_file, "VIEW")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			view_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif view_name.startswith("AV_") :
				f = update_f
			elif view_name.startswith("ZAV_") :
				f = update_f
			else : 
				f = ignore_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#-------------#
# TYPE BODIES #
#-------------#
if os.path.exists(type_bodies_file) :
	headers, name_pattern, data = get_headers(type_bodies_file, "TYPE BODY")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			type_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif type_name.startswith("SYS_") : 
				f = ignore_f
			elif "$" in type_name : 
				f = ignore_f
			else : 
				f = update_f 
			f.write("%s\n%s\n" % (headers[i], sql))
#----------------#
# PACKAGE BODIES #
#----------------#
if os.path.exists(package_bodies_file) :
	headers, name_pattern, data = get_headers(package_bodies_file, "PACKAGE BODY")
	if headers :
		pos2 = data.find(headers[0])
		for i in range(len(headers)) :
			pos1 = pos2 + len(headers[i])+1
			if i == len(headers) - 1 :
				pos2 = len(data)
			else :
				pos2 = data.find(headers[i+1], pos1)
			sql = data[pos1:pos2]
			package_name = name_pattern.match(headers[i]).group(1)
			if   sql.startswith("Unable to compare objects.") : 
				f = ignore_f
			elif package_name.startswith("CWMS_") : 
				f = update_f
			else : 
				f = ignore_f 
			f.write("%s\n%s\n" % (headers[i], sql))
update_f.write(epilog)
update_f.close()
ignore_f.close()


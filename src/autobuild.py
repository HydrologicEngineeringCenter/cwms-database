#!/bin/env python
import glob, gzip, os, sys, tarfile

#-----------------------------------------------------#
# create an automatic version of the buildCWMS_DB.sql #
# script that has the prmopts replaced by defines     #
#-----------------------------------------------------#
manual_sqlfilename = "buildCWMS_DB.sql"
auto_sqlfilename   = "autobuild.sql"
schema_tarfilename = 'cwms_schema.tar'
schema_zipfilename = schema_tarfilename + '.gz'

defines_sqlfilename = "cwms/defines.sql"

prompt_block = \
'''
--
-- prompt for info
--
@@py_prompt
'''

auto_block_template = \
'''
define echo_state = %s
define inst = %s
define sys_passwd = %s
define cwms_schema = %s
define cwms_passwd = %s
define dbi_passwd = %s
define test_passwd = %s
'''

defines_block_template = \
'''
define echo_state = %s
define inst = %s
define cwms_schema = %s
'''

restricted = False
echo, inst, sys_passwd, cwms_schema, cwms_passwd, dbi_passwd, test_passwd = None, None, None, None, None, None, None
for arg in sys.argv[1:] : 
	if arg.find("=") != -1 : 
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
	elif arg.lower() in ("-restricted", "/restricted") :
                restricted = True

		
if not (echo and inst and sys_passwd and cwms_schema and cwms_passwd and dbi_passwd and test_passwd) :
	print("\nUsage %s echo=(on|off) inst=<SID> sys_passwd=<pw> cwms_schema=<schema> cwms_passwd=<pw> dbi_passwd=<pw> test_passwd=<pw>\n" % sys.argv[0])
	sys.exit(-1)

cwms_schema = cwms_schema.upper()
inst = inst.upper()

auto_block = auto_block_template % (echo, inst, sys_passwd, cwms_schema, cwms_passwd, dbi_passwd, test_passwd)
defines_block = defines_block_template % (echo, inst, cwms_schema)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
f.close()
if restricted :
        sql_script = sql_script.replace(
                "--ALTER SYSTEM ENABLE RESTRICTED SESSION;",
                "ALTER SYSTEM ENABLE RESTRICTED SESSION;")
	sql_script = sql_script.replace(
                "--ALTER SYSTEM DISABLE RESTRICTED SESSION;",
                "ALTER SYSTEM DISABLE RESTRICTED SESSION;")
	sql_script = sql_script.replace(
                "--EXEC DBMS_LOCK.SLEEP(1)",
                "EXEC DBMS_LOCK.SLEEP(1)")



f = open(auto_sqlfilename, "w")
f.write(sql_script.replace(prompt_block, auto_block))
f.close()

f = open(defines_sqlfilename, "w")
f.write(defines_block)
f.close()

#--------------------------------------------------#
# extract the current cwms_schema info for loading #
#--------------------------------------------------#
extfilenames = []
if os.path.exists(schema_zipfilename) :
	print("Uncompressing %s..." % schema_zipfilename)
	z = gzip.open(schema_zipfilename, 'rb')
	t = open(schema_tarfilename, 'wb')
	t.write(z.read())
	t.close()
	z.close()
	print("Extracting %s..." % schema_tarfilename)
	t = tarfile.TarFile(schema_tarfilename, 'r')
	extfilenames = t.getnames()
	t.extractall()
	t.close()

#---------------------------------------------#
# execute the automatic version of the script #
#---------------------------------------------#
cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print(cmd)
ec = os.system(cmd)
#os.remove(auto_sqlfilename)
if ec :
	print("\nSQL*Plus exited with code %s\n" % ec)
	sys.exit(-1)

#----------------------------------------------------#
# use SQL*Loader to load any control files generated #
# by buildSqlScripts.py                              #
#----------------------------------------------------#
print("Loading control files")
loaderCmdTemplate = "sqlldr %s/%s@%s control=%s"
for loaderFilename in glob.glob('*.ctl') + glob.glob('data/*.ctl') :
	#-------------------------------#
	# fixup pathnames for clob data #
	#-------------------------------#
	if os.sep != '\\' and os.path.basename(loaderFilename).lower() == 'ddl_clobs.ctl' :
		f = open(loaderFilename)
		data = f.read().replace('\\', os.sep)
		f.close()
		f.open(loaderFilename, 'w')
		f.write(data)
		f.close()
	loaderCmd = loaderCmdTemplate % (cwms_schema, cwms_passwd, inst, loaderFilename)
	print("...%s" % loaderFilename)
	ec = os.system(loaderCmd)
	if ec :
		print("\nSQL*Loader exited with code %s\n" % ec)
		sys.exit(-1)

#---------#
# cleanup #
#---------#
for filename in extfilenames + [schema_tarfilename] :
	if os.path.exists(filename) :
	   try    : os.remove(filename)
	   except : pass

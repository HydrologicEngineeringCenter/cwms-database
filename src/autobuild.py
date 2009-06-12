#!/bin/env python
import fnmatch, os, sys

#--------------------------------------------------------#
# create an automatic version of the buildCWMS_20_DB.sql #
# script that has the prmopts replaced by defines        #
#--------------------------------------------------------#
manual_sqlfilename = "buildCWMS_20_DB.sql"
auto_sqlfilename   = "autobuild.sql"

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
define cwms_passwd = %s
define dbi_passwd = %s
define test_passwd = %s
'''

echo, inst, sys_passwd, cwms_passwd, dbi_passwd, test_passwd = None, None, None, None, None, None
for arg in sys.argv[1:] : 
	if arg.find("=") != -1 : 
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
		
if not (echo and inst and sys_passwd and cwms_passwd and dbi_passwd and test_passwd) :
	print
	print "Usage %s echo=(on|off) inst=<SID> sys_passwd=<pw> cwms_passwd=<pw> dbi_passwd=<pw> test_passwd=<pw>" % sys.argv[0]
	print
	sys.exit(-1)

auto_block = auto_block_template % (echo, inst, sys_passwd, cwms_passwd, dbi_passwd, test_passwd)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
f.close()

f = open(auto_sqlfilename, "w")
f.write(sql_script.replace(prompt_block, auto_block))
f.close()
#---------------------------------------------#
# execute the automatic version of the script #
#---------------------------------------------#
cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print cmd
ec = os.system(cmd)
os.remove(auto_sqlfilename)
if ec :
	print
	print "SQL*Plus exited with code", ec 
	print
	sys.exit(ec)
	
#----------------------------------------------------#
# use SQL*Loader to load any control files generated #
# by buildSqlScripts.py                              #
#----------------------------------------------------#
loaderCmdTemplate = "sqlldr cwms_20/%s@%s control=%s"
for loaderFilename in [fn for fn in os.listdir(".") if fnmatch.fnmatch(fn, "*Loader.ctl")] :
	loaderCmd = loaderCmdTemplate % (cwms_passwd, inst, loaderFilename)
	ec = os.system(loaderCmd)
	if ec :
		print
		print "SQL*Loader exited with code", ec 
		print
		sys.exit(ec)
		

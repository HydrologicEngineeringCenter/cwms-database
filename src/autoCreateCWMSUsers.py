#!/bin/env python
import os, sys

manual_sqlfilename = "createCWMSUsers.sql"
auto_sqlfilename   = "autoCreateCWMSUsers.sql"

prompt_block = \
'''
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept cwms_schema  char prompt 'Enter cwms schema name    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
set echo &echo_state
'''

auto_block_template = \
'''
define echo = %s
define inst = %s
define cwms_schema = %s
define sys_passwd = %s
'''

force = False
echo, inst, cwms_schema,sys_passwd = None, None, None, None
for arg in sys.argv[1:] : 
	if arg.find("=") != -1 : 
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
	elif arg.lower() in ("-force", "/force") :
		force = True
		
if not (echo and inst and cwms_schema and sys_passwd) :
	print
	print "Usage %s echo=(on|off) inst=<SID>  cwms_schema=<schema> sys_passwd=<system password> [-force]" % sys.argv[0]
	print
	print "The -force option keeps the script from exiting on errors."
	print
	sys.exit(-1)
	
cwms_schema = cwms_schema.upper()
inst = inst.upper()


auto_block = auto_block_template % (echo, inst, cwms_schema, sys_passwd)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
f.close()

if force : 
	sql_script = sql_script.replace(
		"whenever sqlerror exit sql.sqlcode", 
		"whenever sqlerror continue")
		
f = open(auto_sqlfilename, "w")
f.write(sql_script.replace(prompt_block, auto_block))
f.close()

cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print cmd
ec = os.system(cmd)
#os.remove(auto_sqlfilename)

if ec :
	print
	print "SQL*Plus exited with code", ec 
	print
	sys.exit(-1)	
	
sys.exit(0)

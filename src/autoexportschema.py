#!/bin/env python
import os, sys

manual_sqlfilename = "exportImportCWMS_DB.sql"
auto_sqlfilename   = "autoexportschema.sql"

prompt_block = \
'''
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept cwms_schema  char prompt 'Enter cwms schema name    : '
accept cwms_passwd  char prompt 'Enter the password for cwms  schema   : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
accept cwms_dir  char prompt 'Enter directory for storing export file   : '
accept ccp_passwd  char prompt 'Enter the password for CCP   : '
set echo &echo_state
'''

auto_block_template = \
'''
define echo = %s
define inst = %s
define cwms_schema = %s
define cwms_passwd = %s
define sys_passwd = %s
define cwms_dir = %s
define ccp_passwd = %s
'''

force = False
restricted = False
echo, inst, cwms_passwd, sys_passwd, cwms_schema, cwms_dir, ccp_passwd = None, None, None, None, None, None, None
for arg in sys.argv[1:] : 
	if arg.find("=") != -1 : 
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
	elif arg.lower() in ("-force", "/force") :
		force = True
        elif arg.lower() in ("-restricted", "/restricted") :
                restricted = True

		
if not (echo and inst and sys_passwd and cwms_passwd and cwms_schema and cwms_dir and ccp_passwd) :
	print
	print "Usage %s echo=(on|off) inst=<SID> cwms_passwd=<password> sys_passwd=<password> cwms_schema=<schema> cwms_dir=<dir name> ccp_passwd=<ccp password> [-force]" % sys.argv[0]
	print
	print "The -force option keeps the script from exiting on errors."
	print
	sys.exit(-1)
	
cwms_schema = cwms_schema.upper()
inst = inst.upper()


auto_block = auto_block_template % (echo, inst, cwms_schema, cwms_passwd, sys_passwd, cwms_dir,ccp_passwd)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
sql_script = sql_script.replace(
                "--EXPORT_SCHEMA('&CWMS_SCHEMA','cwms_export_dump');",
                "EXPORT_SCHEMA('&CWMS_SCHEMA','cwms_export_dump');")
sql_script = sql_script.replace(
                "exportImportCWMS_DB",
                "exportCWMS_SCHEMA")

f.close()

if force : 
	sql_script = sql_script.replace(
		"whenever sqlerror exit sql.sqlcode", 
		"whenever sqlerror continue")
if restricted :
        sql_script = sql_script.replace(
                "--EXECUTE IMMEDIATE 'ALTER SYSTEM ENABLE RESTRICTED SESSION';",
                "EXECUTE IMMEDIATE 'ALTER SYSTEM ENABLE RESTRICTED SESSION';")
        sql_script = sql_script.replace(
                "--EXECUTE IMMEDIATE 'ALTER SYSTEM DISABLE RESTRICTED SESSION';",
                "EXECUTE IMMEDIATE 'ALTER SYSTEM DISABLE RESTRICTED SESSION';")

		
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

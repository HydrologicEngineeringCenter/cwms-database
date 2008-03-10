import os, sys

manual_sqlfilename = "killCWMS_20_DB.sql"
auto_sqlfilename   = "autokill.sql"

prompt_block = \
'''
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
prompt '***************************************************************'
prompt '***                                                         ***'
prompt '*** Warning: This will completely remove all CWMS_20 schema ***'
prompt '*** objects!                                                ***'
prompt '***                                                         ***'
prompt '*** Press Ctrl-C now if you do not wish to continue!        ***'
prompt '***                                                         ***'
prompt '*** Otherwise, press Enter.                                 ***'
prompt '***                                                         ***'
prompt '***************************************************************'
accept dummy char noprompt
'''

auto_block_template = \
'''
define echo_state = %s
define inst = %s
define sys_passwd = %s
'''

echo, inst, sys_passwd = None, None, None
for arg in sys.argv[1:] : 
	if arg.find("=") != -1 : 
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
		
if not (echo and inst and sys_passwd) :
	print
	print "Usage %s echo=(on|off) inst=<SID> sys_passwd=<password>" % sys.argv[0]
	print
	sys.exit(-1)

auto_block = auto_block_template % (echo, inst, sys_passwd)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
f.close()

f = open(auto_sqlfilename, "w")
f.write(sql_script.replace(prompt_block, auto_block))
f.close()

cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print cmd
os.system(cmd)
os.remove(auto_sqlfilename)

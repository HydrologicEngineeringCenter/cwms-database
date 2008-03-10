import os, sys

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

cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print cmd
os.system(cmd)
os.remove(auto_sqlfilename)

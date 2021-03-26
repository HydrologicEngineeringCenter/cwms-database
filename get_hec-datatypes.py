from java.lang import Class
from java.sql  import DriverManager
from java.util import Properties
import getopt, os, re, sys, traceback
reload(sys)
sys.setdefaultencoding('UTF8')

def usage(msg=None) :
   '''
   Spews a usage blurb to stderr and exits
   '''
   program_name = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
   blurb = '''
      %s: Program for extracting hec-datatypes.xsd file from database.

      Usage: %s -d database -u db_user -p db_pass -f office -o out_dir

      Where: database = database connection string as host:port:sid
             db_user  = the database user (this user's schema will be documented)
             db_pass  = the password for the database user
             office   = the default office for the user
             out_dir  = the directory to output the html files in

   ''' % (program_name, program_name)
   if msg :
      sys.stderr.write('\n')
      for line in msg.strip().split('\n') :sys.stderr.write("      %s\n" % line)
   sys.stderr.write(blurb)
   sys.exit(-1)

VALUE, IS_SET = 0, 1
option_info = {
   'd' : [None, False, 'Database'],
   'u' : [None, False, 'User name'],
   'p' : [None, False, 'Password'],
   'f' : [None, False, 'Office'],
   'o' : [None, False, 'Output directory']
}
option_chars = option_info.keys()
opts, args = getopt.gnu_getopt(sys.argv[1:], ':'.join(option_chars+['']))
for opt, val in opts :
   opt_char = opt[1]
   if opt_char == 'd' and val == '' and args:
      val = args[0]
      args = args[1:]
   if opt_char in option_chars :
      opt_val, is_set, item_name = option_info[opt_char]
      if is_set : usage("%s already set" % item_name)
      option_info[opt_char][VALUE] = val
      option_info[opt_char][IS_SET] = True
   else :
      usage('Unexpected option specified: %s' % opt)
error_message = ''
for opt in option_chars :
   if not option_info[opt][1] : error_message += "%s not specified\n" % option_info[opt][2]
if error_message : usage(error_message)
if args : usage('Unexpected argument specified: %s' % args[0])
conn_str   = option_info['d'][VALUE]
username   = option_info['u'][VALUE]
password   = option_info['p'][VALUE]
office     = option_info['f'][VALUE]
output_dir = option_info['o'][VALUE]

if not os.path.exists(output_dir) or not os.path.isdir(output_dir) :
   usage('Directory %s does not exist or is not a directory' % output_dir)
#---------------------#
# connect to database #
#---------------------#
db_url     = 'jdbc:oracle:thin:@%s' % (conn_str)
stmt   = None
rs     = None
print("connecting to " + db_url + " as " + username+ " with pw " + password)

info = Properties()
info.put("user",username)
info.put("password",password)
info.put("oracle.net.disableOob","true")
conn = None
try :
   conn=DriverManager.getConnection(db_url,info);
   set_office_stmt = conn.prepareCall("call cwms_env.set_session_office_id(?)")
   set_office_stmt.setString(1,office)
   set_office_stmt.execute()
   conn.setAutoCommit(False)
   #--------------#
   # get the file #
   #--------------#
   stmt = conn.prepareStatement('select cwms_util.get_hec_datatypes_xsd from dual');
   rs = stmt.executeQuery()
   rs.next()
   clob = rs.getClob(1)
   data = clob.getSubString(1, clob.length())
   data = "\n".join(data.split("\r\n"))
   outfile = os.path.join(output_dir, "hec-datatypes.xsd")
   with open(outfile, 'w') as f :
      f.write(data)
   print("%s bytes written to %s" % (len(data), outfile))
except :
    traceback.print_exc()
    sys.exit(-1)
finally :
	if conn is not None : conn.close()


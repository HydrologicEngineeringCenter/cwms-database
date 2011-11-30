from __future__      import with_statement
from java.io         import File, FileReader, FileWriter
from java.nio        import CharBuffer
from java.lang       import String
from wcds.dbi.client import JdbcConnection
import getopt, os, sys

program_dir = os.path.dirname(sys.argv[0])
if program_dir not in sys.path : sys.path.append(program_dir)
import schema_utils

program_name = os.path.splitext(os.path.basename(sys.argv[0]))[0]
obj_types = ['TABLE', 'VIEW', 'PACKAGE', 'PACKAGE_BODY', 'TYPE', 'TYPE_BODY', 'DATA']


usage_blurb = \
   '''
   Usage: %s <Parameters>

   Parameters : -d <database> or --database <database>
                -u <username> or --username <username>
                -p <password> or --password <password>
                -t <obj_type> or --type     <obj_type>
                -n <obj_name> or --name     <obj_name>

   All parameters are required except that the object name is not required if
   the object type is DATA, in which case the static data are compared.

   Valid object types are "%s".

''' % (program_name, '", "'.join(obj_types))

database = None
username = None
password = None
obj_type = None
obj_name = None

def usage(message = None) :
   if message : sys.stderr.write('\n%s\n' % message)
   sys.stderr.write(usage_blurb)
   sys.exit(-1)

def run_cmd(cmd) :
   _cmd_ = cmd.strip()
   print(_cmd_)
   return os.system(_cmd_)

#---------------------#
# handle command line #
#---------------------#
opts, args = getopt.getopt(
   sys.argv[1:],
   'd:u:p:t:n:',
   ['database=', 'username=', 'password=', 'type=', 'name='])

if args :
   usage('Unexpected parameter(s) : %s' % ', '.join(['%s' % arg for arg in args]))

for key, value in opts :
   if key in ('-d', '--database') :
      if database : usage('Database already specified as %s' % database)
      database = value
   elif key in ('-u', '--username') :
      if username : usage('Username already specified as %s' % username)
      username = value
   elif key in ('-p', '--password') :
      if password : usage('Password already specified as %s' % password)
      password = value
   elif key in ('-t', '--type') :
      if obj_type : usage('Object type already specified as %s' % obj_type)
      obj_type = value.upper()
      if obj_type not in obj_types : usage('Invalid object type %s, must be one of %s' % (obj_type, ', '.join(obj_types)))
   elif key in ('-n', '--name') :
      if obj_name : usage('Object name already specified as %s' % obj_name)
      obj_name = value.upper()
      if obj_type == 'DATA' : usage('No object name allowed with object type DATA')

#-----------------------------------------------#
# prompt for any parameters not on command line #
#-----------------------------------------------#
if not database : database = raw_input('Enter database    : ')
if not database : sys.exit(-1)
if not username : username = raw_input('Enter username    : ')
if not username : sys.exit(-1)
if not password : password = raw_input('Enter password    : ')
if not password : sys.exit(-1)
if not obj_type : obj_type = raw_input('Enter object type : ').upper()
if not obj_type : sys.exit(-1)
if obj_type not in obj_types : usage('Invalid object type %s, must be one of %s' % (obj_type, ', '.join(obj_types)))
if obj_type == 'DATA' :
   if obj_name : usage('No object name allowed with object type DATA')
else :
   if not obj_name : obj_name = raw_input('Enter object name : ').upper()
   if not obj_name : sys.exit(-1)
if obj_name : obj_name = obj_name.split('.')[-1]

#-------------------------#
# connect to the database #
#-------------------------#
schemaname = username.upper()
conn = stmt = rs = deployed = current = None
conn = JdbcConnection.getConnection('jdbc:oracle:thin:@%s' % database,  username, password)
if not conn :
   sys.stderr.write('\nCould not connect to %s as %s\n\n' % (database, username))
   sys.exit(-1)
try :
   if obj_type == 'DATA' :
      stmt = conn.prepareStatement('select cwms_schema.get_schema_version from dual')
      rs = stmt.executeQuery()
      if rs.next() :
         v = rs.getString(1)[19:].strip()
      else :
         sys.stderr.write('\nCould not determine the current schema!\n\n')
         sys.exit(-1)
      stmt.close()
      stmt = conn.prepareStatement("select value from at_clob where office_code = 53 and id = '/DDL/STATIC_DATA/%s'" % v)
      rs = stmt.executeQuery()
      if rs.next() :
         d = String(rs.getString(1))
      else :
         sys.stderr.write('\nNo static data found for schema version %s\n\n' % v)
         sys.exit(-1)
      s = File.createTempFile(program_name, '.sql')
      t = File.createTempFile('current', '.log')
      script = schema_utils.get_static_data(t.getCanonicalPath(), schemaname, conn)
      fw = FileWriter(s)
      fw.write(script, 0, len(script))
      fw.write('exit\n', 0, 5)
      fw.close()
      cmd = 'sqlplus %s/%s@%s @%s' % (username, password, database, s.getCanonicalPath())
      rc = os.system(cmd)
      try    : os.remove(s.getCanonicalPath())
      except : pass
      if rc :
         try    : os.remove(t.getCanonicalPath())
         except : pass
         sys.exit(rc)
      buf = CharBuffer.allocate(t.length())
      fr = FileReader(t)
      fr.read(buf)
      fr.close()
      c = String(buf.rewind().toString())
   else :
      stmt = conn.prepareCall('begin cwms_schema.compare_ddl(:1, :2); end;')
      stmt.setString(1, obj_type)
      stmt.setString(2, obj_name)
      stmt.execute()
      stmt.close()
      stmt = conn.prepareStatement('select * from at_schema_object_diff')
      rs = stmt.executeQuery()
      if rs.next() :
         assert rs.getString(1) == obj_type
         assert rs.getString(2) == obj_name
         v = rs.getString(3)
         d = String(rs.getString(4))
         c = String(rs.getString(5))
      else :
         sys.stderr.write('\nNo such object as %s %s\n\n' % (obj_type, obj_name))
         sys.exit(-1)
   deployed = File.createTempFile('deployed', '.txt')
   d = String(d.replaceAll('"%s"' % schemaname, '"<cwms_schema>"'))
   d = String(d.replaceAll('SYS_[A-Z0-9_$]+', '<sys_defined_name>'))
   fw = FileWriter(deployed)
   fw.write(d, 0, d.length())
   fw.close()
   current = File.createTempFile('current', '.txt')
   c = String(c.replaceAll('"%s"' % schemaname, '"<cwms_schema>"'))
   c = String(c.replaceAll('SYS_[A-Z0-9_$]+', '<sys_defined_name>'))
   fw = FileWriter(current)
   fw.write(c, 0, c.length())
   fw.close()
   diff_cmd = os.getenv('DIFF', 'diff')
   run_cmd('%s %s %s' % (diff_cmd, deployed.getCanonicalPath(), current.getCanonicalPath()))
finally :
   for resource in rs, stmt, conn :
      try    : resource.close()
      except : pass
   for tmpfile in deployed, current :
      if tmpfile :
         try    : os.remove(tmpfile.getCanonicalPath())
         except : pass

from java.sql        import Types
from wcds.dbi.client import JdbcConnection
import getopt, os, sys

program_dir = os.path.dirname(sys.argv[0])
if program_dir not in sys.path : sys.path.append(program_dir)
import schema_utils

program_name = os.path.splitext(os.path.basename(sys.argv[0]))[0]


usage_blurb = \
   '''
   Usage: %s <Parameters>

   Parameters : -d <database> or --database <database>
                -u <username> or --username <username>
                -p <password> or --password <password>

   All parameters are required.

''' % program_name

database = None
username = None
password = None

def usage(message = None) :
   if message : sys.stderr.write('\n%s\n' % message)
   sys.stderr.write(usage_blurb)
   sys.exit(-1)

enable_sql = 'begin dbms_output.enable(:1); end;'
output_sql = 'begin cwms_schema.output_latest_results; end;'
show_sql = '''
declare
   l_line   varchar2(255);
   l_done   number;
   l_buffer long;
begin
   loop
      exit when length(l_buffer)+255 > :maxbytes or l_done = 1;
      dbms_output.get_line(l_line, l_done);
      l_buffer := l_buffer || l_line || chr(10);
   end loop;
   :done := l_done;
   :buffer := l_buffer;
end;
'''

#---------------------#
# handle command line #
#---------------------#
opts, args = getopt.getopt(
   sys.argv[1:],
   'd:u:p:',
   ['database=', 'username=', 'password='])

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

#-----------------------------------------------#
# prompt for any parameters not on command line #
#-----------------------------------------------#
if not database : database = raw_input('Enter database    : ')
if not database : sys.exit(-1)
if not username : username = raw_input('Enter username    : ')
if not username : sys.exit(-1)
if not password : password = raw_input('Enter password    : ')
if not password : sys.exit(-1)

#-------------------------#
# connect to the database #
#-------------------------#
conn = stmt = rs = deployed = current = None
conn = JdbcConnection.getConnection('jdbc:oracle:thin:@%s' % database,  username, password)
if not conn :
   sys.stderr.write('\nCould not connect to %s as %s\n\n' % (database, username))
   sys.exit(-1)
try :
   stmt = conn.prepareCall(enable_sql)
   stmt.setInt(1, 2000000)
   stmt.executeUpdate()
   stmt.close()
   stmt = conn.prepareCall(output_sql);
   stmt.executeUpdate()
   stmt.close()
   stmt = conn.prepareCall(show_sql)
   stmt.setInt(1, 32000)
   stmt.registerOutParameter(2, Types.INTEGER)
   stmt.registerOutParameter(3, Types.VARCHAR)
   while True :
      stmt.executeUpdate()
      sys.stdout.write(stmt.getString(3))
      if stmt.getInt(2) == 1 : break
   stmt.close()
finally :
   conn.close()

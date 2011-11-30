from __future__      import with_statement
from java.sql        import Types
from wcds.dbi.client import JdbcConnection
import codecs, datetime, getopt, glob, gzip, os, sys, tarfile

start_time = datetime.datetime.now()
program_dir = os.path.dirname(sys.argv[0])
if program_dir not in sys.path : sys.path.append(program_dir)
import schema_utils

program_name = os.path.splitext(os.path.basename(sys.argv[0]))[0]
data_dir = 'data'
sql_filename = '%s.sql' % program_name
txt_filename = '%s.txt' % program_name
ins_filename = os.path.join(data_dir, 'cwms_schema_object_version.sql')
inp_filename = os.path.join(data_dir, 'ddl_clobs.ctl')
tar_filename = 'cwms_schema.tar'
zip_filename = '%s.gz' % tar_filename

usage_blurb = \
   '''
   Usage: %s <Parameters>

   Parameters : -d <database> or --database <database>
                -u <username> or --username <username>
                -p <password> or --password <password>
                -v <version>  or --version  <version> 
                -c <comment>  or --comment  <comment> 
                -w <dir>      or --workdir  <dir>     

   All parameters are required except the comment and the working directory.

   If the comment is not specified, no comment will be use.
   If the working directory is not specified, the current directory will be used.

   The working directory must map to //wcdba/dev/oracle/dev/src in Perforce.
   ''' % program_name

inp_header = \
'''
load data
infile *
append
into table at_clob
fields terminated by ','
(
   clob_code   "cwms_seq.nextval",
   office_code constant 53,
   id,
   description constant '',
   filename    filler,
   value       lobfile(filename) terminated by eof
)
begindata
'''.lstrip()

database = None
username = None
password = None
version  = None
comment  = None
workdir  = None

def usage(message = None) :
   if message : sys.stderr.write('\n%s\n' % message)
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
   'd:u:p:v:c:w:',
   ['database=', 'username=', 'password=', 'version=', 'comment=', 'workdir='])

if args :
   usage('Unexpected parameter(s) :', ', '.join(['%s' % arg for arg in args]))

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
   elif key in ('-v', '--version') :
      if version : usage('Version already specified as %s' % version)
      version = value
   elif key in ('-c', '--comment') :
      if comment : usage('Comment already specified as %s' % comment)
      comment = value
   elif key in ('-w', '--workdir') :
      if workdir : usage('working directory already specified as %s' % workdir)
      workdir = value
#-----------------------------------------------#
# prompt for any parameters not on command line #
#-----------------------------------------------#
prompts = 0
if not database : database = raw_input('Enter database : '); prompts += 1
if not database : sys.exit(-1)
if not username : username = raw_input('Enter username : '); prompts += 1
if not username : sys.exit(-1)
if not password : password = raw_input('Enter password : '); prompts += 1
if not password : sys.exit(-1)
if not version  : version  = raw_input('Enter version  : '); prompts += 1
if not version  : sys.exit(-1)
if prompts > 0  :
   if not comment : comment  = raw_input('Enter comment  : ')
   if not workdir : workdir  = raw_input('Enter workdir  : ')
if not comment  : comment = ''
if not workdir  : workdir = '.'
schemaname = username.upper()
#---------------------------------#
# checkout the tar file and untar #
#---------------------------------#
os.chdir(workdir)
run_cmd('p4 edit %s' % zip_filename)
run_cmd('del %s' % os.path.join(data_dir, 'DDL!*.txt'))
for filename in ins_filename, inp_filename :
   try    : os.remove(filename)
   except : pass
print("Uncompressing...")
z = gzip.open(zip_filename, 'rb')
t = open(tar_filename, 'wb')
t.write(z.read())
t.close()
z.close()
t = tarfile.TarFile(tar_filename, 'r')
print("Extracting %d files..." % len(t.getnames()))
t.extractall()
t.close()

conn = JdbcConnection.getConnection('jdbc:oracle:thin:@%s' % database,  username, password)
try :
   #------------------------------#
   # generate the SQL*Plus script #
   #------------------------------#
   f = open(sql_filename, 'w')
   f.write('''whenever sqlerror exit sql.sqlcode
   set serveroutput on
   begin
      cwms_schema.set_schema_version('%s', '%s');
      commit;
   end;
   /
   ''' % (version, comment))
   f.write(schema_utils.get_static_data(txt_filename, schemaname, conn))
   f.write('exit\n')
   f.close()
   #-------------------------#
   # run the SQL*Plus script #
   #-------------------------#
   cmd = 'sqlplus %s/%s@%s @%s' % (username, password, database, sql_filename)
   rc = os.system(cmd)
   if rc : sys.exit(rc)
   #--------------------------------------#
   # load the static data to the database #
   #--------------------------------------#
   with open(txt_filename, 'r') as f : static_data = f.read()
   stmt = conn.prepareCall('begin :1 := cwms_text.store_text(:2, :3, :4, :5, :6); end;')
   stmt.registerOutParameter(1, Types.NUMERIC)
   stmt.setStringForClob(2, static_data)
   stmt.setString(3, '/DDL/STATIC_DATA/%s' % version.upper())
   stmt.setString(4, 'Static data in tables')
   stmt.setString(5, 'F')
   stmt.setString(6, 'CWMS')
   stmt.execute()
   conn.commit()
   stmt.close()
   #--------------------------------------------------------#
   # create a loading script for cwms_schema_object_version #
   #--------------------------------------------------------#
   # find the schema object lines in the static data
   pos1 = static_data.find('table cwms_schema_object_version')
   pos2 = static_data.find('rows selected', pos1)
   lines = static_data[pos1:pos2].split('\n')[3:-2]
   # find the field positions from the separator line
   separator, lines = lines[0], lines[1:]
   field_pos = []
   pos1 = separator.find('-')
   pos2 = separator.find(' ', pos1)
   while True :
      field_pos.append((pos1, pos2))
      pos1 = separator.find('-', pos2)
      if pos1 == -1 : break
      pos2 = separator.find(' ', pos1)
      if pos2 == -1 : pos2 = len(separator)
   field_count = len(field_pos)
   fields = [''] * field_count
   # create an insert sql statement from each line
   with open(ins_filename, 'w') as f :
      for line in lines :
         if not line or line.startswith('-') or line.startswith('HASH_CODE') : continue
         for i in range(field_count) :
            fields[i] = line[field_pos[i][0]:field_pos[i][1]].strip().replace("'", "''")
         f.write('insert into cwms_schema_object_version values(%s);\n' % ','.join(["'%s'" % field for field in fields]))
   #--------------------------------#
   # export ddl clobs for reloading #
   #--------------------------------#
   old_clobfiles = glob.glob(os.path.join(data_dir, 'DDL!*.txt'))
   new_clobfiles = []
   stmt = conn.prepareStatement("select id from at_clob where id like '/DDL/%'")
   rs = stmt.executeQuery()
   while rs.next() :
      id = rs.getString(1)
      new_clobfiles.append(os.path.join(data_dir, "%s.txt" % id[1:].replace('/', '!')))
   rs.close()
   for clobfilename in  [f for f in old_clobfiles if f not in new_clobfiles] :
      try    : os.remove(clobfilename)
      except : pass
   stmt = conn.prepareStatement('select value from at_clob where id = :1')
   for clobfilename in new_clobfiles :
      id = '/%s' % os.path.basename(clobfilename)[:-4].replace('!', '/')
      stmt.setString(1, id)
      rs = stmt.executeQuery()
      if rs.next() :
         clob = rs.getClob(1)
         print("Writing file %s" % clobfilename)
         with codecs.open(clobfilename, mode='wt', encoding='utf-8') as clobfile :
            clobfile.write(clob.getSubString(1, clob.length()))
      else :
         print("Couldn't retrieve clob %s" % id)
      rs.close()
   stmt.close()
   #---------------------------------------------#
   # build a file for sql*loader to reload clobs #
   #---------------------------------------------#
   with open(inp_filename, 'w') as f :
      f.write(inp_header)
      for clobfilename in new_clobfiles :
         id = '/%s' % os.path.basename(clobfilename)[:-4].replace('!', '/')
         f.write('0,%s,%s\n' % (id, clobfilename))
   #---------------------------#
   # build and zip the tarfile #
   #---------------------------#
   print("Writing file %s" % tar_filename)
   t = tarfile.TarFile(tar_filename, 'w')
   files_to_add = [ins_filename, inp_filename] + new_clobfiles
   for filename in files_to_add :
      print("..adding %s" % filename)
      t.add(filename)
   print("%d files added." % len(files_to_add))
   t.close()
   print("Compressing...")
   t = open(tar_filename, 'rb')
   z = gzip.open(zip_filename, 'wb')
   z.writelines(t)
   z.close()
   t.close()

   #----------------------#
   # checkin the tar file #
   #----------------------#
   run_cmd('p4 submit -d "%s" %s' % ('Update for CWMS schema version %s' % version, os.path.normpath(zip_filename)))
finally :
   #---------#
   # cleanup #
   #---------#
   conn.close()
   for filename in sql_filename, txt_filename :
      try    : os.remove(filename)
      except : pass
   end_time = datetime.datetime.now()
   print('\nProgram %s was active for %s' % (program_name, str(end_time - start_time)))

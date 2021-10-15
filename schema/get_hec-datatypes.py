from java.lang import Class
from java.sql  import DriverManager
from java.util import Properties
import getopt, os, re, sys, traceback
reload(sys)
sys.setdefaultencoding('UTF8')

plsql_function_name = "get_hec_datatypes_xsd"
plsql_function_code = r'''
   create or replace function %s
      return clob
   is
      type entities_t is table of varchar2(32767) index by varchar2(128);
      l_xsd            clob;
      l_template       clob;
      l_dtd            clob;
      l_name           varchar2(128);
      l_name2          varchar2(128);
      l_value          varchar2(32767);
      l_entities       entities_t;
      l_action         varchar2(32767);
      l_action_results str_tab_t;
      l_lines          str_tab_t;
      l_line           varchar2(32767);
      l_schema_version varchar2(16);

      function anycase(p_str in varchar2) return varchar2
      is
         l_results varchar2(32767);
         l_upper   varchar2(1);
         l_lower   varchar2(1);
      begin
         for i in 1..length(p_str) loop
            l_upper := upper(substr(p_str, i, 1));
            l_lower := lower(substr(p_str, i, 1));
            if l_upper = l_lower then
               l_results := l_results||l_upper;
            else
               l_results := l_results||'['||l_upper||l_lower||']';
            end if;
         end loop;
         return l_results;
      end anycase;

   begin
      select version
        into l_schema_version
        from av_db_change_log v
       where database_id = cwms_util.get_db_name
         and apply_date = (select max(apply_date) from av_db_change_log where database_id = v.database_id);
      ---------------------------------------------
      -- get the template from the AT_CLOB table --
      ---------------------------------------------
      select value into l_template from at_clob where id = '/XSD/HEC-DATATYPES-TEMPLATE.XSD';
      ---------------------------------------------------------
      -- separate the template into DTD and non-DTD portions --
      ---------------------------------------------------------
      l_dtd   := regexp_substr(l_template, '<!DOCTYPE\s+\S+\s*\[.+?\]>\s*', 1, 1, 'n');
      l_template  := replace(l_template, l_dtd, null);
      -------------------------------------
      -- process the entities in the DTD --
      -------------------------------------
      for rec in (select trim(column_value) as line from table(cwms_util.split_text(l_dtd, chr(10))) where instr(column_value, '<!ENTITY ') > 0) loop
         l_name  := regexp_substr(rec.line, '<!ENTITY\s+(\S+)\s*"([^"]+)"\s*>', 1, 1, 'c', 1);
         l_value := regexp_substr(rec.line, '<!ENTITY\s+(\S+)\s*"([^"]+)"\s*>', 1, 1, 'c', 2);
         --------------------------------
         -- first replace any entities --
         --------------------------------
         loop
            l_name2 := regexp_substr(l_value, '&[^;]+;');
            exit when l_name2 is null;
            l_value := replace(l_value, l_name2, l_entities(l_name2));
         end loop;
         ------------------------------
         -- next perform any queries --
         ------------------------------
         loop
            l_action := regexp_substr(l_value, '`(select\s.[^`]+)`', 1, 1, 'c', 1);
            exit when l_action is null;
            begin
               execute immediate l_action bulk collect into l_action_results;
            exception
               when others then
                  cwms_err.raise(
                     chr(10)||'ERROR',
                     chr(10)||'Error code  =  '||sqlcode ||
                     chr(10)||'Error msg   =  '||sqlerrm ||
                     chr(10)||'File line   =  '||rec.line||
                     chr(10)||'Entity name =  '||l_name  ||
                     chr(10)||'Value       =  '||l_value ||
                     chr(10)||'Query text  = "'||l_action||'"');
            end;
            case l_action_results.count
            when 0 then l_value := replace(l_value, '`'||l_action||'`', null);
            when 1 then l_value := replace(l_value, '`'||l_action||'`', regexp_replace(l_action_results(1), '([+*])', '\\\1'));
            else l_value := replace(l_value, '`'||l_action||'`', '('||regexp_replace(cwms_util.join_text(l_action_results, '|'), '([+*])', '\\\1')||')');
            end case;
         end loop;
         ----------------------------------------------------------
         -- finally perform any case-insensitive transformations --
         ----------------------------------------------------------
         loop
            l_action := regexp_substr(l_value, '`anycase\(.+\)`');
            exit when l_action is null;
            l_value := replace(l_value, l_action, anycase(substr(l_action, 10, length(l_action)-11)));
         end loop;
         l_entities('&'||l_name||';') := l_value;
      end loop;
      -----------------------------------------------
      -- apply the entities to the non-DTD portion --
      -----------------------------------------------
      dbms_lob.createtemporary(l_xsd, true);
      l_lines := cwms_util.split_text(l_template, chr(10));
      for rec in (select column_value from table(l_lines)) loop
         l_line := rec.column_value;
         loop
            l_name := regexp_substr(l_line, '&[^;]+;');
            exit when l_name is null;
            l_line := replace(l_line, l_name, l_entities(l_name));
         end loop;
         loop
            l_action := regexp_substr(l_line, '`[^`]+`');
            exit when l_action is null;
            case l_action
            when '`schema_version`' then l_line := replace(l_line, l_action, l_schema_version);
            when '`date_time`'      then l_line := replace(l_line, l_action, cwms_util.get_xml_time(sysdate, dbtimezone));
            else cwms_err.raise('ERROR', 'Unexpected action "'||l_action||'" in line "'||l_line||'"');
            end case;
         end loop;
         cwms_util.append(l_xsd, l_line||chr(10));
      end loop;
      return l_xsd;
   end %s;
''' % (plsql_function_name, plsql_function_name)

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
   conn.setAutoCommit(False)
   #---------------------#
   # create the function #
   #---------------------#
   stmt = conn.prepareStatement(plsql_function_code)
   stmt.execute()
   #--------------#
   # get the file #
   #--------------#
   stmt = conn.prepareStatement('select %s from dual' % plsql_function_name);
   rs = stmt.executeQuery()
   rs.next()
   clob = rs.getClob(1)
   data = clob.getSubString(1, clob.length())
   data = "\n".join(data.split("\r\n"))
   #---------------------------------------#
   # drop the function and delete the clob #
   #---------------------------------------#
   stmt = conn.prepareStatement("drop function %s" % plsql_function_name)
   stmt.execute()
   stmt = conn.prepareStatement("delete from at_clob where id = '/XSD/HEC-DATATYPES-TEMPLATE.XSD'")
   stmt.execute()
   #----------------------------------------------------------------#
   # search for invalid regex patterns that eclipse first turned up #
   #----------------------------------------------------------------#
   if re.search("(^|[(|])[+*]", data) is not None :
   	   raise Exception("hec-datatypes.xsd contains invalid regex patterns")
   outfile = os.path.join(output_dir, "hec-datatypes.xsd")
   with open(outfile, 'w') as f :
      f.write(data)
   print("%s bytes written to %s" % (len(data), outfile))
except :
    traceback.print_exc()
    sys.exit(-1)
finally :
	if conn is not None : conn.close()


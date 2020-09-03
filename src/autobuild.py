#!/bin/env python
import glob, gzip, os, sys, tarfile

#-----------------------------------------------------#
# create an automatic version of the buildCWMS_DB.sql #
# script that has the prmopts replaced by defines     #
#-----------------------------------------------------#
manual_sqlfilename = "buildCWMS_DB.sql"
auto_sqlfilename   = "autobuild.sql"

defines_sqlfilename = "cwms/defines.sql"

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
define cwms_schema = %s
define cwms_passwd = %s
define dbi_passwd = %s
define pd_passwd = %s
define test_passwd = %s
'''

defines_block_template = \
'''
define echo_state = %s
define inst = %s
define cwms_schema = %s
define host_office = %s
'''

restricted = False
echo, inst, sys_passwd, cwms_schema, cwms_passwd, dbi_passwd, pd_passwd, test_passwd = None, None, None, None, None, None, None, None
for arg in sys.argv[1:] :
	if arg.find("=") != -1 :
		name, value = arg.split("=", 1)
		arg = "=".join((name, '"%s"' % value))
		exec arg
	elif arg.lower() in ("-restricted", "/restricted") :
                restricted = True


if not (echo and inst and sys_passwd and cwms_schema and cwms_passwd and dbi_passwd and pd_passwd and test_passwd) :
	print("\nUsage %s echo=(on|off) inst=<SID> sys_passwd=<pw> cwms_schema=<schema> cwms_passwd=<pw> dbi_passwd=<pw> test_passwd=<pw>\n" % sys.argv[0])
	sys.exit(-1)

cwms_schema = cwms_schema.upper()
inst = inst.upper()

auto_block = auto_block_template % (echo, inst, sys_passwd, cwms_schema, cwms_passwd, dbi_passwd, pd_passwd, test_passwd)
defines_block = defines_block_template % (echo, inst, cwms_schema, pd_office)

f = open(manual_sqlfilename, "r")
sql_script = f.read()
f.close()
if restricted :
        sql_script = sql_script.replace(
                "--ALTER SYSTEM ENABLE RESTRICTED SESSION;",
                "ALTER SYSTEM ENABLE RESTRICTED SESSION;")
	sql_script = sql_script.replace(
                "--ALTER SYSTEM DISABLE RESTRICTED SESSION;",
                "ALTER SYSTEM DISABLE RESTRICTED SESSION;")
	sql_script = sql_script.replace(
                "--EXEC DBMS_LOCK.SLEEP(1)",
                "EXEC DBMS_LOCK.SLEEP(1)")



f = open(auto_sqlfilename, "w")
f.write(sql_script.replace(prompt_block, auto_block))
f.close()

f = open(defines_sqlfilename, "w")
f.write(defines_block)
f.close()

#---------------------------------------------#
# execute the automatic version of the script #
#---------------------------------------------#
cmd = "sqlplus /nolog @%s" % auto_sqlfilename
print(cmd)
ec = os.system(cmd)
#os.remove(auto_sqlfilename)
if ec :
	print("\nSQL*Plus exited with code %s\n" % ec)
	sys.exit(-1)

#---------------------------------------------------------#
# generate a SQL*Loader control file for the VERTCON data #
#---------------------------------------------------------#
vertconControlFileName = "data/vertcon_clobs.ctl"
vertconControlFileText = '''
load data
	infile *
	append
	into table at_clob
	fields terminated by ','
	(CLOB_CODE, 
	 OFFICE_CODE,                         
	 ID char, 
	 DESCRIPTION char,                         
	 filename FILLER char,
	 VALUE LOBFILE(filename) TERMINATED BY EOF)                 
begindata
-1,53,/VERTCON/VERTASCE.94,VERTCON table for Eastern U.S.,data/vertASCe.94
-2,53,/VERTCON/VERTASCC.94,VERTCON table for Central U.S.,data/vertASCc.94
-3,53,/VERTCON/VERTASCW.94,VERTCON table for Western U.S.,data/vertASCw.94
'''[1:]
f = open(vertconControlFileName, "w")
f.write(vertconControlFileText)
f.close()

#------------------------------------------------------------------#
# generate a SQL*Loader control file for CWMS RADAR XSL transforms #
#------------------------------------------------------------------#
radarXsltControllerFileName = "data/radar_xslt_clobs.ctl"
radarXsltControlFileText = '''
load data
	infile *
	append
	into table at_clob
	fields terminated by ','
	(CLOB_CODE "cwms_20.cwms_seq.nextval", 
	 OFFICE_CODE,                         
	 ID char, 
	 DESCRIPTION char,                         
	 filename FILLER char,
	 VALUE LOBFILE(filename) TERMINATED BY EOF)                 
begindata
-1,53,/XSLT/RATINGS_V1_TO_RADAR_XML,CWMS RADAR Rating Transform to XML,data/Ratings_v1_to_RADAR_xml.xsl
-1,53,/XSLT/RATINGS_V1_TO_RADAR_JSON,CWMS RADAR Rating Transform to JSON,data/Ratings_v1_to_RADAR_json.xsl
-1,53,/XSLT/RATINGS_V1_TO_RADAR_TAB,CWMS RADAR Rating Transform to TAB,data/Ratings_v1_to_RADAR_tab.xsl
'''[1:]
f = open(radarXsltControllerFileName, "w")
f.write(radarXsltControlFileText)
f.close()

#----------------------------------------------------#
# use SQL*Loader to load any control files generated #
# by buildSqlScripts.py                              #
#----------------------------------------------------#
print("Loading control files")
loaderCmdTemplate = "sqlldr %s/\"%s\"@%s control=%s"
for loaderFilename in glob.glob('*.ctl') + glob.glob('data/*.ctl') :
	#-------------------------------#
	# fixup pathnames for clob data #
	#-------------------------------#
	loaderCmd = loaderCmdTemplate % (cwms_schema, cwms_passwd, inst, loaderFilename)
	print("...%s" % loaderFilename)
	ec = os.system(loaderCmd)
	if ec :
		print("\nSQL*Loader exited with code %s\n" % ec)
		sys.exit(-1)

#---------------------------------------------------------#
# generate a script to populate VERTCON tables from clobs #
#---------------------------------------------------------#
vertconScriptText = '''
declare
   l_clob          clob; 
   l_line          varchar2(32767);
   l_pos           integer; 
   l_pos2          integer; 
   l_parts         number_tab_t;
   l_lon_count     integer; 
   l_lat_count     integer; 
   l_z_count       integer; 
   l_min_lon       binary_double; 
   l_delta_lon     binary_double; 
   l_min_lat       binary_double;
   l_delta_lat     binary_double; 
   l_margin        binary_double;
   l_max_lon       binary_double;
   l_max_lat       binary_double;
   l_vals          number_tab_t := number_tab_t(); 
   l_data_set_code number(14);
   l_idx           pls_integer;
   
   procedure get_line(p_line out varchar2) is
      l_amount integer;
      l_buf    varchar2(32767);
   begin
      l_pos2 := dbms_lob.instr(l_clob, chr(10), l_pos, 1);
      if l_pos2 is null or l_pos2 = 0 then
         l_pos2 := dbms_lob.getlength(l_clob) + 1;
      else
         l_pos2 := l_pos2 + 1;
      end if;
      l_amount := greatest(l_pos2 - l_pos, 1);
      dbms_lob.read(l_clob, l_amount, l_pos, l_buf);
      l_pos := l_pos + l_amount;
      p_line := trim(trailing chr(13) from trim(trailing chr(10) from l_buf));
   end;  
begin
   --------------------------------------
   -- for each vertcon ascii data file --
   --------------------------------------
   for rec in (select id from at_clob where clob_code < 0) loop          
      l_vals.delete;
      select value
        into l_clob
        from at_clob
       where id = upper(rec.id);
      dbms_lob.open(l_clob, dbms_lob.lob_readonly);
      l_pos := 1;       
      begin
         ---------------------
         -- read the header --
         ---------------------
         get_line(l_line); 
         get_line(l_line); 
         select column_value
           bulk collect
           into l_parts
           from table(cwms_util.split_text(trim(l_line)));
         if l_parts(3) != 1 then
            cwms_err.raise('ERROR', 'z_count must equal 1');
         end if;
         l_lon_count := l_parts(1);
         l_lat_count := l_parts(2);
         l_z_count   := l_parts(3);
         l_min_lon   := l_parts(4);
         l_delta_lon := l_parts(5);
         l_min_lat   := l_parts(6);
         l_delta_lat := l_parts(7);
         l_margin    := l_parts(8);
         l_max_lon := l_min_lon + (l_lon_count - 1) * l_delta_lon;
         l_max_lat := l_min_lat + (l_lat_count - 1) * l_delta_lat;
         l_vals.extend(l_lon_count * l_lat_count);
         ---------------------------------
         -- read the datum shift values --
         -- into a linear (1-D) table   --
         ---------------------------------
         l_idx := 0;
         <<read_vals>>
         while true loop
            begin
               get_line(l_line);   
               select column_value
                 bulk collect
                 into l_parts
                 from table(cwms_util.split_text(trim(l_line)));
               for j in 1..l_parts.count loop 
                  l_vals(l_idx+j) := l_parts(j);
               end loop;
               l_idx := l_idx + l_parts.count;
            exception
               when no_data_found then exit read_vals;
            end;
         end loop;
      exception
         when others then 
            dbms_lob.close(l_clob);
            raise;
      end;
      dbms_lob.close(l_clob);
      --------------------------
      -- load the header data --
      --------------------------
      insert
        into cwms_vertcon_header
             ( office_code,
               dataset_code,
               dataset_id,
               min_lat,
               max_lat,
               min_lon,
               max_lon,
               margin,
               delta_lat,
               delta_lon
             )
      values ( cwms_util.db_office_code_all,
               cwms_seq.nextval,
               replace(replace(lower(rec.id), 'asc', 'con'), '/vertcon/', ''),
               l_min_lat,
               l_max_lat,
               l_min_lon,
               l_max_lon,
               l_margin,
               l_delta_lat,
               l_delta_lon 
             )
   returning dataset_code
        into l_data_set_code;               
      -------------------------      
      -- load the table data --
      -------------------------      
      for j in 1..l_lat_count loop
         for k in 1..l_lon_count loop
            insert
              into cwms_vertcon_data
                   ( dataset_code,
                     table_row,
                     table_col,
                     table_val
                   )
            values ( l_data_set_code,
                     j,
                     k,
                     l_vals((j-1)*l_lon_count+k)
                   );
         end loop;
      end loop;      
   end loop;
   
   delete
     from at_clob
    where clob_code < 0;
    
   commit;    
end;
/
exit
'''[1:]
vertconScriptFileName = "populateVertconTables.sql"
f = open(vertconScriptFileName, "w")
f.write(vertconScriptText)
f.close()

#------------------------------------------------------#
# run the script to populate VERTCON tables from clobs #
#------------------------------------------------------#
cmd = "sqlplus %s/\"%s\"@%s @%s" % (cwms_schema, cwms_passwd, inst, vertconScriptFileName)
print("Executing %s" % vertconScriptFileName)
ec = os.system(cmd)
if ec :
	print("\nSQL*Plus exited with code %s\n" % ec)
	sys.exit(-1)

#---------#
# cleanup #
#---------#
for filename in (vertconScriptFileName, vertconControlFileName) :
	if os.path.exists(filename) :
	   try    : os.remove(filename)
	   except : pass
	   

from glob import glob
import os, re, sys
#-------------------#
# example data file #
#-------------------#
"""
declare
   l_database_id varchar2(30);
begin
   select nvl(primary_db_unique_name, db_unique_name)
     into l_database_id
     from v$database;

   insert
     into cwms_db_change_log
          (office_code,
           database_id,
           application,
           ver_major,
           ver_minor,
           ver_build,
           ver_date,
           title,
           description
          )
   values (cwms_util.user_office_code,
           l_database_id,
           'CWMS',
           18,
           1,
           9,
           to_date ('02FEB2021', 'DDMONYYYY'),
           'CWMS Database Release 18.1.9',
           'Bug fixes to 18.1.8'
          );
   commit;
end;
"""
#---------------------------------------------------#
# parse version information from the update scripts #
#---------------------------------------------------#
updates = []
base_dir = os.path.join(os.path.dirname(sys.argv[0]), "src", "updateScripts")
for pn in glob(os.path.join(base_dir, "*_*_*")) :
	if os.path.isdir(pn) and re.match("\d+_\d+_\d+", os.path.split(pn)[-1]) :
		script_name = os.path.join(pn, "update_db_change_log.sql")
		if os.path.exists(script_name) :
			with open(script_name, "r") as f : text = f.read()
			# print(text)
			m = re.search(
				r"values\s*.+'CWMS'\s*,\s*(\d+)"        +\
					r"\s*,\s*(\d+)"                     +\
					r"\s*,\s*(\d+)"                     +\
					r"\s*,\s*to_date\s*\(\s*'(.+?)\s*'" +\
					r"\s*,\s*'\s*(.+?)\s*'\s*\)"        +\
					r"\s*,\s*'\s*(.+?)\s*'"             +\
					r"\s*,\s*'\s*(.+?)\s*'",
				text,
				re.I|re.M|re.S)

			if m :
				major, minor, patch, datestr, datefmt, title, description = [m.group(i) for i in range(1, 8)]
				major, minor, patch = map(int, (major, minor, patch))
				updates.append((major, minor, patch, datestr, datefmt, title, description))
#------------------------#
# get the latest version #
#------------------------#
major, minor, patch, datestr, datefmt, title, description = sorted(updates)[-1]
#------------------------------------------------------#
# output SQL command to insert into CWMS_DB_CHANGE_LOG #
#------------------------------------------------------#
print("insert into cwms_db_change_log values ({0},{1},'CWMS',{2},{3},{4},to_date('{5}','{6}'), sysdate,'{7}','{8}');".format(
	"cwms_util.get_db_office_code",
	"cwms_util.get_db_name",
	major,
	minor,
	patch,
	datestr,
	datefmt,
	title,
	description))
print("commit;")

import os, subprocess, sys,datetime
from subprocess import check_output
moduleName = "buildSqlScripts"
argv = sys.argv
outFile  = None
#-----------------------------------------#
# get program directory from command line #
#-----------------------------------------#
progDir, progName = os.path.split(sys.argv[0])
progName = os.path.splitext(progName)[0]
print("%s : Starting up" % progName)
#-------------------------------------------------#
# compute output file name from program directory #
#-------------------------------------------------#
progDir    = os.path.normpath(progDir)
buildVer   = os.path.split(progDir)[1]

if (len(argv) == 2): 
	outFile = argv[1]
elif (len(argv) < 2):
	sys.stderr.write("Usage: python build_db_parameters_def.py <output file>\n")
	sys.stderr.write("Ex:    python build_db_parameters_def.py build/resources/cwms/data/db_parameter_units.def")
	sys.exit(-1)

#----------------------------------------------------------------------#
# import the buildSqlScripts script used to generate the static schema #
#----------------------------------------------------------------------#
importDir = os.path.join(progDir, "src")
if importDir not in sys.path : sys.path.append(importDir)
print("%s : Importing %s.py" % (progName, os.path.join(importDir, moduleName)))
exec("import %s" % moduleName)
#------------------------------------------------------------------------------------#
# use the parameters variable from the imported script to generate the resource file #
#------------------------------------------------------------------------------------#
params = sorted([[p[2],p[5],p[6]] for p in buildSqlScripts.parameters])
maxIdLen = max([len(param[0]) for param in params])
maxSiLen = max([len(param[1]) for param in params])
format = "%%-%ds : %%-%ds : %%s\n" % (maxIdLen, maxSiLen)
print("%s : Writing resource file %s" % (progName, outFile))
f = open(outFile, "w")
date_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
git_branch = check_output(["git","branch","--show-current"]).strip()
teamcity_build_info = "(manual run)"
try:
	build_number = os.environ["BUILD_NUMBER"]
	build = os.environ["TEAMCITY_BUILDCONF_NAME"]
	teamcity_build_info = "(Build %s, #%s)" % (build,build_number)
except:
	pass # we aren't in TEAMCITY so these don't exist
f.write("// Generated from cwms_database:" + str(git_branch) + " " + str(teamcity_build_info) + " on " + str(date_str) + "\n" )
f.write("=PARAMETER/UNIT\n")
f.write("#position=100\n\n")
for param_id, si_unit, en_unit in params :
	f.write(format % (param_id, si_unit, en_unit))
f.close()

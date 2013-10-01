import os, subprocess, sys
moduleName = "buildSqlScripts"
argv = sys.argv
hecjavadevDir = "../../../../hecjavadev"
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

if (len(argv) == 4): 
	hecjavadevDir = argv[1]
	buildVer = argv[2]
	p4WorkspaceName = argv[3]
elif (len(argv) > 1):
	sys.stderr.write("Usage: python build_db_parameters_def.py <hecjavadev_dir> <build_version> <p4_workspace_name> \n")
	sys.stderr.write("Ex:    python buildSqlScripts.py build_db_parameters_def.py ../hecjavadev dev COMPUTE01-wcdba-v1.0\n")
	sys.exit(-1)

outputDir  = os.path.normpath(os.path.join(progDir, hecjavadevDir, buildVer, "apps/config/db/definitions"))
outputFile = os.path.join(outputDir, "db_parameters_units.def")
#----------------------------------------------------------------------#
# import the buildSqlScripts script used to generate the static schema #
#----------------------------------------------------------------------#
importDir = os.path.join(progDir, "src")
if importDir not in sys.path : sys.path.append(importDir)
print("%s : Importing %s.py" % (progName, os.path.join(importDir, moduleName)))
exec("import %s" % moduleName)
#-----------------------------------------#
# checkout the resource file if it exists #
#-----------------------------------------#
oldFileData = None
exists = os.path.exists(outputFile)
if exists :
	f = open(outputFile, "r")
	oldFileData = f.read()
	f.close()
	if (len(argv) == 4):
		cmd = "p4 -c %s edit %s" % (p4WorkspaceName, outputFile)
	else:
		cmd = "p4 edit %s" % outputFile
	print("%s : %s" % (progName, cmd))
	subprocess.call(cmd)
#------------------------------------------------------------------------------------#
# use the parameters variable from the imported script to generate the resource file #
#------------------------------------------------------------------------------------#
params = sorted([[p[2],p[5],p[6]] for p in buildSqlScripts.parameters])
maxIdLen = max([len(param[0]) for param in params])
maxSiLen = max([len(param[1]) for param in params])
format = "%%-%ds : %%-%ds : %%s\n" % (maxIdLen, maxSiLen)
print("%s : Writing resource file %s" % (progName, outputFile))
f = open(outputFile, "w")
f.write("\n=PARAMETER/UNIT\n")
f.write("#position=100\n\n")
for param_id, si_unit, en_unit in params :
	f.write(format % (param_id, si_unit, en_unit))
f.close()
f = open(outputFile, "r")
newFileData = f.read()
f.close()
#------------------------------------------#
# add the resource file if it didn't exist #
#------------------------------------------#
if not exists :
	if (len(argv) == 4):
		cmd = "p4 -c %s add %s" % (p4WorkspaceName, outputFile)
	else:
		cmd = "p4 add %s" % outputFile
	print("%s : %s" % (progName, cmd))
	subprocess.call(cmd)	
#------------------------------------#
# submit or revert the resource file #
#------------------------------------#
if newFileData == oldFileData :
	if (len(argv) == 4):
		cmd = "p4 -c %s revert %s" % (p4WorkspaceName, outputFile)
	else:
		cmd = "p4 revert %s" % outputFile
else :
	if (len(argv) == 4):
		cmd = "p4 -c %s submit -d auto_update %s" % (p4WorkspaceName, outputFile)
	else:
		cmd = "p4 submit -d auto_update %s" % outputFile
print("%s : %s" % (progName, cmd))
subprocess.call(cmd)


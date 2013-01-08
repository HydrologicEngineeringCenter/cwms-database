import os, subprocess, sys
moduleName = "buildSqlScripts"
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
outputDir  = os.path.normpath(os.path.join(progDir, "../../../../hecjavadev", buildVer, "apps/config/db/definitions"))
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
	cmd = "p4 edit %s" % outputFile
	print("%s : %s" % (progName, cmd))
	subprocess.call(cmd)
#------------------------------------------------------------------------------------#
# use the parameters variable from the imported script to generate the resource file #
#------------------------------------------------------------------------------------#
params = sorted([[p[2],p[5],p[6]] for p in buildSqlScripts.parameters if p[0] > 0])
maxIdLen = max([len(param[0]) for param in params])
maxSiLen = max([len(param[1]) for param in params])
format = "%%-%ds : %%-%ds : %%s\n" % (maxIdLen, maxSiLen)
print("%s : Writing resource file %s" % (progName, outputFile))
f = open(outputFile, "w")
f.write("\n=PARAMETER/UNIT\n\n")
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
	cmd = "p4 add %s" % outputFile
	print("%s : %s" % (progName, cmd))
	subprocess.call(cmd)
#------------------------------------#
# submit or revert the resource file #
#------------------------------------#
if newFileData == oldFileData :
	cmd = "p4 revert %s" % outputFile
else :	
	cmd = "p4 submit -d auto_update %s" % outputFile
print("%s : %s" % (progName, cmd))
subprocess.call(cmd)


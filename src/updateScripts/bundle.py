#!/bin/env python
import os, sys, traceback, zipfile

filenames = set()
missing_filenames = set()

def usage(message = None) :
	'''
	Spews usage blub with optional error message
	'''
	if message : sys.stderr.write("\n%s\n" % message)
	progname = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
	sys.stderr.write('''
Program %s bundles schema update scripts for transferring to remote
	systems for local execution.

Usage : %s <schema_update_script>

Output: %s.zip

''' % (progname, progname, progname))

def addfilenames(filename) :
	'''
	Adds filename and any called filenames
	'''
	global fileanames, startdir
	#-------------------------------------------------------#
	# parse the actual file name from the variable provided #
	#-------------------------------------------------------#
	filename = filename.lstrip("@")
	notfound = 10000
	comments = ["--", "/*"]
	pos = min(map(lambda p : p if p > 0 else notfound, [filename.find(s) for s in comments]))
	if pos != notfound :
		#-----------------------------------------#
		# first strip off any comments at the end #
		#-----------------------------------------#
		filename = filename[:pos]
	pos = filename.find(".sql")
	if pos != -1 :
		#----------------------------------------#
		# if ".sql" is present we can stop there #
		#----------------------------------------#
		filename = filename[:pos+4]
	else :
		#------------------------------------------------------------#
		# strip off any script parameters until we find the filename #
		#------------------------------------------------------------#
		while len(filename.split()) > 1 and not os.path.isfile(filename) and not os.path.isfile(filename+".sql") :
			filename = " ".join(filename.split()[:-1])
	#-----------------------------------------------------------------#
	# split filename into dir and basename and cd to dir if necessary #
	#-----------------------------------------------------------------#
	olddir = os.getcwd()
	dirname, filename = os.path.split(filename)
	if dirname and dirname != "." :
		if os.path.exists(dirname) :
			os.chdir(dirname)
		else :
			os.chdir(startdir)
			if os.path.exists(dirname) :
				os.chdir(dirname)
			else :
				raise Exception("Directory %s cannot be found from %s or %s" % (dirname, olddir, startdir))
	#---------------------------#
	# add the .sql if necessary #
	#---------------------------#
	if not os.path.splitext(filename)[1] :
		filename += ".sql"
	#-------------------------------------------#
	# add this file and any scripts it contains #
	#-------------------------------------------#
	print(os.path.abspath(filename))
	if not os.path.exists(filename) :
		print("No such file: %s" % filename)
		missing_filenames.add(os.path.abspath(filename))
	else :
		filenames.add(os.path.abspath(filename))
		with open(filename) as f :
			lines = f.read().strip().split("\n")
		for line in lines :
			if line.strip().startswith("@") :
				addfilenames(line)
	#--------------------------------------#
	# finally, cd back to the previous dir #
	#--------------------------------------#
	os.chdir(olddir)

#--------------------------#
# process the command line #
#--------------------------#
try :
	scriptfilename = sys.argv[1]
except IndexError :
	usage()
except :
	traceback.print_exc()

if not os.path.isfile(scriptfilename) :
	usage("No such file: %s" % scriptfilename)

#---------------------------#
# build the list of scripts #
#---------------------------#
startdir = os.getcwd()
addfilenames(scriptfilename)
if scriptfilename == "update_3.0.7_to_18.1.1.sql" :
	extrafilenames = [
		"18_1_1/load_data.py",
		"18_1_1/load_data.py",
		"18_1_1/CWMS_NID_DATA_TABLE.ctl",
		"18_1_1/CWMS_NID2_DATA_TABLE.ctl",
		"18_1_1/radar_xslt_clobs.ctl",
		"../data/Ratings_v1_to_RADAR_xml.xsl",
		"../data/Ratings_v1_to_RADAR_json.xsl",
		"../data/Ratings_v1_to_RADAR_tab.xsl"
	]
	for fn in extrafilenames :
		if os.path.exists(fn) :
			filenames.add(os.path.abspath(fn))
		else :
			missing_filenames.add(fn)


if missing_filenames :
	print("\nCouldn't find the following reqruied files:")
	for filename in sorted(missing_filenames) :
		print("\t%s" % filename)
	print("\nScript %s not bundled\n" % scriptfilename)
	exit()
#------------------------------------------------------#
# determine the longest common path to all the scripts #
#------------------------------------------------------#
commonparts = None
for filename in filenames :
	parts = filename.split(os.sep)
	if not commonparts :
		commonparts = parts[:-1]
	else :
		for i in range(len(commonparts)) :
			if parts[i] != commonparts[i] :
				commonparts = commonparts[:i]
				break
commondir = os.sep.join(commonparts)

#--------------------#
# build the zip file #
#--------------------#
zipfilename = os.path.splitext(scriptfilename)[0] + ".zip"
zf = zipfile.ZipFile(zipfilename, 'w')
print("Created zip file %s" % zipfilename)
olddir = os.getcwd()
os.chdir(commondir)
for filename in sorted(filenames) :
	archivename = filename.replace(commondir, ".")
	print("...adding %s" % archivename)
	zf.write(archivename)
os.chdir(olddir)
zf.close()
print("\nBundled %s into %s" % (scriptfilename, zipfilename))

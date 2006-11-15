#
# This script should be executed with the python.path property set such that it
# includes the CLASSPATH environment variable (in addition to jythonLib.jar, of
# course).
#
# The cwmsdb package lives in Perforce at //wcdba/dev/dist/java/lib/cwmsdb.jar.
# Since the java source for the classes in it were created using jpub, which in
# turn uses SQLJ, the SQLJ runtime classes are also required.  I used the 
# following from the C:\oracle\product\10.2.0\client_1\sqlj\lib directory: 
#  - runtime12.jar
#  - sqljutl.jar
#  - translator.jar 
#
# Classpath that worked:
#
# CLASSPATH=.;C:\JAVA\JAKARTA\JAKARTA-ORO-2.0.8.JAR;C:\JAVA\JEXCELAPI\JXL.JAR;C:\ORACLE\PRODUCT\10.2.0\CLIENT_1\JDBC\LIB\OJDBC14.J
# AR;C:\ORACLE\PRODUCT\10.2.0\CLIENT_1\SQLJ\LIB\SQLJUTL.JAR;C:\ORACLE\PRODUCT\10.2.0\CLIENT_1\SQLJ\LIB\TRANSLATOR.JAR;C:\ORACLE\PR
# ODUCT\10.2.0\CLIENT_1\SQLJ\LIB\RUNTIME12.JAR;C:\JAVA\JYTHON-2.1\JYTHON.JAR;C:\JAVA\J2SDK1.4.2_10\JRE\LIB\CHARSETS.JAR;C:\JAVA\J2
# SDK1.4.2_10\JRE\LIB\DEPLOY.JAR;C:\JAVA\J2SDK1.4.2_10\JRE\LIB\JAVAWS.JAR;C:\JAVA\J2SDK1.4.2_10\JRE\LIB\JCE.JAR;C:\JAVA\J2SDK1.4.2
# _10\JRE\LIB\JSSE.JAR;C:\JAVA\J2SDK1.4.2_10\JRE\LIB\PLUGIN.JAR;C:\JAVA\J2SDK1.4.2_10\JRE\LIB\RT.JAR;C:\JAVA\J2SDK1.4.2_10\LIB\TOO
# LS.JAR;C:\JAVA\J2SDK1.4.2_10\LIB\DT.JAR;C:\JAVA\J2SDK1.4.2_10\LIB\HTMLCONVERTER.JAR;C:\JAVA\J2SDK1.4.2_10\LIB\JCONSOLE.JAR;U:\De
# vl\Perforce\wcdba\dev\dist\java\lib\cwmsdb.jar;j:\dev\code
#
# Command line that worked :
#
# java -DCWMS_HOME=j:\dev\apps -Dpython.path=j:\dev\apps\jar\jythonLib.jar;%CLASSPATH% 
# org.python.util.jython loadTsData.py -Dcritfile=t:\drot.crit -Ddatafile=t:\drot.shortData
#

#---------#
# Imports #
#---------#
import os, sys, string, time, StringIO

from cwmsdb             import CwmsCatJdbc, CwmsTsJdbc
from hec.data           import Interval, IntervalOffset, Units
from hec.data.tx        import DescriptionTx
from hec.lang.Const     import UNDEFINED_DOUBLE
from java.lang          import System
from java.sql           import DriverManager, Timestamp
from java.text          import SimpleDateFormat
from java.util          import Date, GregorianCalendar, TimeZone
from oracle.jdbc.driver import OracleDriver

#-------------------------------------------------------#
# Process any property definitions passed to the script #
#-------------------------------------------------------#
for arg in sys.argv[1:] :
	if arg.startswith("-D") :
		try    : key, value = arg[2:].split("=")
		except : key, value = arg[2:], 1
		os.environ[key] = value

critFilename = os.environ["CRITFILE"]
dataFilename = os.environ["DATAFILE"]

#--------------------#
# Static definitions #
#--------------------#
TRUE  = 1
FALSE = 0

ONLY_ELEMENT  = 0
FIRST_ELEMENT = 1
NEXT_ELEMENT  = 2

UTC_OFFSET_IRREGULAR = -2147483648L
UTC_OFFSET_UNDEFINED =  2147483647L

TZ                = "TZ"
DLTIME            = "DLTime"
UNITS             = "Units"
INTERVAL_OFFSET   = "IntervalOffset"
INTERVAL_BACKWARD = "IntervalBackward"
INTERVAL_FORWARD  = "IntervalForward"

critRecordKeys = [
	TZ,
	DLTIME,
	UNITS,
	INTERVAL_OFFSET,
	INTERVAL_BACKWARD,
	INTERVAL_FORWARD
]

REPLACE_ALL                 = "Replace All"
DO_NOT_REPLACE              = "Do Not Replace"
REPLACE_MISSING_VALUES_ONLY = "Replace Missing Values Only"
REPLACE_WITH_NON_MISSING    = "Replace With Non Missing"
DELETE_INSERT               = "Delete Insert"

storeRules = [
	REPLACE_ALL,
	DO_NOT_REPLACE,
	REPLACE_MISSING_VALUES_ONLY,
	REPLACE_WITH_NON_MISSING,
	DELETE_INSERT
]

tzUtc = TimeZone.getTimeZone("UTC")

dateFormatUtc     = SimpleDateFormat("yyyy/MM/dd HH:mm:ss z")
dateFormatDefault = SimpleDateFormat("yyyy/MM/dd HH:mm:ss z")
dateFormatUtc.setTimeZone(tzUtc)
dateFormatDefault.setTimeZone(TimeZone.getDefault())

cal = GregorianCalendar(tzUtc)
cal.set(1111, 10, 11, 0, 0, 0)
NON_VERSIONED = Timestamp(cal.getTimeInMillis())

#------------------#
# Define functions #
#------------------#
def readCritFile(critFilename) :
	'''
	Read the criteria file and verify the UTC_INTERVAL_OFFSET for
	each record.
	'''
	critRecords = {}
	critFile = open(critFilename, "r")
	now = Date(System.currentTimeMillis())
	#----------------------------#
	# First read the entire file #
	#----------------------------#
	print "At %s (%s) : Reading criteria file" % (dateFormatUtc.format(now), dateFormatDefault.format(now)) 
	lines = critFile.read().split("\n")
	critFile.close()
	now = Date(System.currentTimeMillis())
	print "At %s (%s) : Validating criteria file" % (dateFormatUtc.format(now), dateFormatDefault.format(now))
	
	#----------------------------------------------------#
	# Redirect stdout to a buffer while we're validating #
	#----------------------------------------------------#
	errors = StringIO.StringIO()
	sys.stdout = errors
	
	#---------------------------------------#
	# Now process and validate line-by-line #
	#---------------------------------------#
	validatedAgainstDbCount = 0 
	for line in lines :
		line = line.strip()
		if not line or line.startswith("#") : continue
		
		#---------------------------------------------------------------#
		# Crack the record and analyze the criteria record key and tsid #
		#---------------------------------------------------------------#
		fields = map(string.strip, line.split(";"))
		critKey, tsid = map(string.strip, fields[0].split("="))
		if critRecords.has_key(critKey) :
			print
			print "Criteria is already specified: %s" % critKey
			print "Criteria Record = %s" % line
			continue
		critRecords[critKey] = {"TSID" : tsid}
		try :
			descTx = DescriptionTx(tsid)
			isRegular = descTx.getInterval().isRegular()
		except :
			print
			print "Invalid Criteria Record"
			print "Criteria Record = %s" % line
			continue
		
		#---------------------------------------------------------#
		# So far, so good - analyze the remaining key/value pairs #
		#---------------------------------------------------------#
		critRecord = critRecords[critKey]
		for field in fields[1:] :
			key, value = map(string.strip, field.split("="))
			if key not in critRecordKeys :
				print
				print "Invalid Criteria Record Key: %s" % key
				print "Criteria Record = %s" % line
				continue
			critRecord[key] = value

		#-----------------------------------------------------#			
		# Check for appropriate use of interval-related stuff #
		#-----------------------------------------------------#			
		if isRegular :
			for key in (INTERVAL_BACKWARD, INTERVAL_FORWARD) :
				if critRecord.has_key(key) and not critRecord.has_key(INTERVAL_OFFSET) :
					print
					print 'Cannot have "%s" without "%s"' % (key, INTERVAL_OFFSET)
					print "Criteria Record = %s" % line
					continue
		else :
			for key in (INTERVAL_OFFSET, INTERVAL_BACKWARD, INTERVAL_FORWARD) :
				if critRecord.has_key(key) :
					print
					print 'Irregular time series cannot specify "%s"' % key
					print "Criteria Record = %s" % line
					continue
					
		#---------------------------------------------------#					
		# Validate utc interval offset against the database #
		#---------------------------------------------------#					
		rs = cwmsCat.catTs(officeId, tsid)
		if rs.next() : 
			offset = rs.getLong(3)
			if not rs.wasNull() : validatedAgainstDbCount += 1
		else :
			rs.close()
			rs = None
		if not rs or rs.wasNull() :
			if isRegular :
				offset = UTC_OFFSET_UNDEFINED
			else :
				offset = UTC_OFFSET_IRREGULAR
		if rs : rs.close()
		if critRecord.has_key(INTERVAL_OFFSET) :
			if critRecord[INTERVAL_OFFSET] != offset :
				print
				print "Interval offset mismatch!"
				print "Criteria Record = %s" % line
				print "Database offset = %d" % offset
				continue
		else :
			critRecord[INTERVAL_OFFSET] = offset
			
	#-------------------------------------------------------------------------------#
	# Collect any error messgages we generated and put stdout back where it belongs #
	#-------------------------------------------------------------------------------#
	errorText = errors.getvalue()
	errors.close()
	sys.stdout = sys.__stdout__
	
	#--------------------------------------#
	# If we had errors, spew them and quit #
	#--------------------------------------#
	if len(errorText) > 0 :
		print "At %s (%s) : Criteria file has the following errors:\n%s" % (
			dateFormatUtc.format(now), 
			dateFormatDefault.format(now),
			errorText) 
		jdbcConn.close()
		sys.exit()
		
	#----------#			
	# Success! #
	#----------#			
	print "At %s (%s) : %d criteria records successfully validated (%d against database)" % (
		dateFormatUtc.format(now), 
		dateFormatDefault.format(now),
		len(critRecords),
		validatedAgainstDbCount) 
	return critRecords

def getCritKey(line) :
	'''
	Get the criteria record key from the shefit -2 format line
	'''
	critKey = ".".join((
		line[:8].strip(),
		line[38:40],
		line[41:44],
		line[63:67].strip()))
	return critKey
	
def loadData(dataLines) :
	'''
	Load some shefit -2 format lines into the database.
	
	This currently doesn't do anything with the DLTime crit value, nor does
	it attempt any OTF validation/transformation.
	'''
	global transactionCount, transactionElapsedTime, transactionValuesLoaded
	
	if not dataLines : return
	
	#------------------------------------------------------#
	# Get the criteria record info for this group of lines #
	#------------------------------------------------------#
	critRecord = critRecords[getCritKey(dataLines[0])]
	tsid  = critRecord["TSID"]
	units = critRecord["Units"]
	descTx = DescriptionTx(tsid)
	intervalName = descTx.getIntervalName()
	offsetSeconds = critRecord[INTERVAL_OFFSET]
	if critRecord.has_key(INTERVAL_BACKWARD) :
		o = IntervalOffset()
		o.setIntervalOffset(critRecord[INTERVAL_BACKWARD])
		backwardSeconds = o.getOffset()
	else :
		backwardSeconds = 0
	if critRecord.has_key(INTERVAL_FORWARD) :
		o = IntervalOffset()
		o.setIntervalOffset(critRecord[INTERVAL_FORWARD])
		forwardSeconds = o.getOffset()
	else :
		forwardSeconds = 0

	#----------------------#		
	# Print the log header #
	#----------------------#		
	now = Date(System.currentTimeMillis())
	print
	print "At %s (%s)" % (dateFormatUtc.format(now), dateFormatDefault.format(now)) 
	print tsid
	
	#-------------------------------------------------#
	# Initialize arrays, etc... and process each line #
	#-------------------------------------------------#
	times   = []
	values  = []
	quality = []
	tz = TimeZone.getTimeZone(critRecord["TZ"])
	cal = GregorianCalendar(tz)
	for line in dataLines :
		#--------------#
		# Get the time #
		#--------------#
		y, m, d, h, n, s = map(int, (
			line[8:12],
			line[12:14].strip(),
			line[14:16].strip(),
			line[16:18].strip(),
			line[18:20].strip(),
			line[20:22].strip()))
		cal.set(y, m-1, d, h, n, s)
		millis = cal.getTimeInMillis()
		seconds = millis / 1000
		
		#------------------------------------------------------#
		# Validate UTC interval offset for regular time series #
		#------------------------------------------------------#
		if descTx.getInterval().isRegular() :
			intervalTop = Interval.getTimeAtTopOfIntervalOnOrBefore(
				millis, 
				intervalName, 
				tzUtc)
			intervalTopSeconds = intervalTop / 1000
			
			#-----------------------------------------------------#
			# Initialize the interval offset if it is unspecified #
			# in the criteria record and the datase               #
			#-----------------------------------------------------#
			if offsetSeconds == UTC_OFFSET_UNDEFINED :
				offsetSeconds = seconds - intervalTopSeconds
				critRecord[INTERVAL_OFFSET] = offsetSeconds
				
			#-----------------------------------------------------#
			# If the interval offset is incorrect, snap it if the #
			# criteria record specifies to do so                  #
			#-----------------------------------------------------#
			if seconds - intervalTopSeconds != offsetSeconds :
				if backwardSeconds or forwardSeconds :
					#----------------------------------------------------------#
					# Make sure our interval actually surrounds the value time #
					#----------------------------------------------------------#
					if offsetSeconds >= (seconds - intervalTopSeconds) :
						intervalTop = Interval.getTimeAtTopOfIntervalOnOrBefore(
							intervalTop-1, 
							intervalName, 
							tzUtc) 
					intervalNext = Inteval.getTimeAtNextInterval(
						intervalTop, 
						intervalName, 
						tzUtc)
					intervalNextSeconds = intervalNext / 1000
					intervalTopSeconds += offsetSeconds
					intervalNextSeconds += offsetSeconds
					#-------------------------------------#
					# Try snapping ahead first, then back #
					#-------------------------------------#
					if intervalNextSeconds - backwardSeconds <= seconds :
						seconds = intervalNextSeconds
					elif seconds - intervalTopSeconds <= forwardSeconds :
						seconds = intervalTopSeconds
					#------------------------------------#
					# Readjust the interval if necessary #
					#------------------------------------#
					intervalTop = Interval.getTimeAtTopOfIntervalOnOrBefore(
						seconds * 1000, 
						intervalName, 
						tzUtc)
					intervalTopSeconds = intervalTop / 1000
			
			#---------------------------------------------------------#
			# Now spew an error if we don't match the interval offset #
			#---------------------------------------------------------#
			if seconds - intervalTopSeconds != offsetSeconds :
				print "-->%s is not on UTC interval offset." % dateFormatUtc.format(cal.getTime())
				print "-->Criteria record :"
				print "\t%s" % critRecord
				print "-->Data Record :"
				print "\t%s" % line
				continue
		
		#------------------------------------------------------------------#
		# Everything matched OK (or is irregular), so append to the arrays #
		#------------------------------------------------------------------#
		times.append(seconds * 1000)
		value = float(line[44:54].strip())
		if value == -9999.0 :
			value = UNDEFINED_DOUBLE
			qual = 1
		else :
			qual = 0
		values.append(value)
		quality.append(qual)
		
	#--------------------------------------#
	# Load the data, if we accumulated any #
	#--------------------------------------#
	count = len(times)
	if count > 0 :
		#-------------------------#
		# Handle decreasing times #
		#-------------------------#
		if count > 1 and times[1] < times[0] :
			times.reverse()
			values.reverse()
			quality.reverse()

		#----------------------------------------#			
		# Call the API and note the elapsed time #
		#----------------------------------------#			
		startTime = time.time()
		cwmsTs.store(
			officeId,
			tsid,
			units,
			times,
			values, 
			quality,
			count,
			storeRule,
			FALSE,
			NON_VERSIONED)
		endTime = time.time()
		
		#------------------------------------#
		# Accumulate totals for ending stats #
		#------------------------------------#
		elapsedTime = endTime - startTime
		transactionElapsedTime += elapsedTime
		transactionCount += 1
		transactionValuesLoaded += count
		
		#--------------------------------------#
		# Output the remainder of the log info #
		#--------------------------------------#
		elapsedMillis = int(elapsedTime * 1000.0 + .5)
		print "\t%d value(s) loaded in %d milliseconds." % (count, elapsedMillis)
		print '\tData units are "%s".' % units
		if count < 5 : toPrint = range(count)
		else         : toPrint = (0, 1, count-2, count-1)
		for i in toPrint :
			if count > 4 and i == count - 2 : print "\t..."
			cal.setTimeInMillis(times[i])
			date = cal.getTime()
			print "\t%-4d %s (%s) %f" % (
				i + 1,
				dateFormatUtc.format(date), 
				dateFormatDefault.format(date), 
				values[i])

#-----------------------------------------------------------------------------#
# Get user input (redirect stdout in case stdout is redirectd outside script) #
#-----------------------------------------------------------------------------#
sys.stdout = sys.__stderr__
connStr = raw_input("\nEnter DB Connection String (user/pass@tnsName)\n-->")
officeId = raw_input("\nEnter Office ID for data\n-->")[:2].upper()
validNumbers = range(1, len(storeRules) + 1)
prompt = ""
for i in range(len(storeRules)) : prompt += "\n%d : %s" % (i + 1, storeRules[i])
prompt += "\n\nEnter the number of the desired store rule.\n-->"
i = 0
while not i in validNumbers :
	try :
		i = int(raw_input(prompt))
	except :
		i = 0
storeRule = storeRules[i-1]
sys.stdout = sys.__stdout__

#-------------------------#		
# Connect to the database #
#-------------------------#		
username, other   = connStr.split("/")
password, tnsName = other.split("@") 
dbUrl      = "jdbc:oracle:oci:@%s" % tnsName 
jdbcDriver = DriverManager.registerDriver(OracleDriver());
jdbcConn   = DriverManager.getConnection(dbUrl, username, password);

#----------------------------------#
# Initialize cwmsdb access objects #
#----------------------------------#
cwmsCat = CwmsCatJdbc(jdbcConn)
cwmsTs  = CwmsTsJdbc(jdbcConn)

transactionCount        = 0
transactionValuesLoaded = 0
transactionElapsedTime  = 0. 

#---------------------------------------#	
# OK, everything is setup, get to work! #
#---------------------------------------#
dataFile = None
try :
	critRecords = readCritFile(critFilename)
	dataFile = open(dataFilename, "r")
	groupLines  = []
	lastCritKey = None
	line = dataFile.readline()
	while line :
		line = line.strip()
		if line :
			critKey = getCritKey(line)
			if critRecords.has_key(critKey) :
				tsKey = int(line[78])
				if tsKey == FIRST_ELEMENT :
					if groupLines : loadData(groupLines)
					groupLines = [line] 
				elif critKey == lastCritKey and tsKey == NEXT_ELEMENT and groupLines :
					groupLines.append(line)
				else :
					if groupLines :
						loadData(groupLines)
						groupLines = []
					loadData([line])
				
		lastCritKey = critKey
		line = dataFile.readline()
		
	if groupLines : loadData(groupLines)
finally :
	#---------------#
	# clean up shop #
	#---------------#
	jdbcConn.close()
	if dataFile : 
		dataFile.close()
		#------------#
		# Spew stats #
		#------------#
		print
		print "Transactions completed : %d" % transactionCount
		print "Values Stored          : %d" % transactionValuesLoaded
		print "Elapsed Time           : %f seconds" % transactionElapsedTime
		transactionCount, transactionValuesLoaded = map(float, (transactionCount, transactionValuesLoaded))
		print "Avg Values / Store     : %f" % (transactionValuesLoaded / transactionCount)
		print "Avg Time / Store       : %d milliseconds" % int((transactionElapsedTime / transactionCount) * 1000. + .5)
		print

	
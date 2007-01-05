#---------#
# Imports #
#---------# 
import os, sys, java, time, string, traceback

for item in os.environ["CLASSPATH"].split(os.pathsep) :
	if item not in sys.path : sys.path.append(item)

import oracle		

#--------------------#
# Static definitions #
#--------------------#
TRUE  = 1
FALSE = 0
serverOutput = FALSE
createXchgSetSql  = "begin :1 := cwms_dss.create_dss_xchg_set(:2,:3,:4,:5,:6,:7,:8); end;"
mapTsInXchgSetSql = "begin cwms_dss.map_ts_in_xchg_set(:1,:2,:3,:4,:5,:6,:7,:8); end;" 
getDssXchgSetsSql = "begin :1 := cwms_dss.get_dss_xchg_sets; end;" 

lastConn = None
getLinesSql  = "begin dbms_output.get_lines(:1,:2); end;"
getLinesStmt = None

def proxyForUser(orclConn, username) :
	time1 = time.time()
	if orclConn.isProxySession() : 
		orclConn.close(oracle.jdbc.OracleConnection.PROXY_SESSION)
	connProps = java.util.Properties()
	connProps.setProperty("PROXY_USER_NAME", username)
	orclConn.openProxySession(oracle.jdbc.OracleConnection.PROXYTYPE_USER_NAME, connProps)
	orclConn.createStatement().execute("alter session set current_schema = cwms_20")
	time2 = time.time()
	print "proxyForUser : %f" % (time2 - time1)

def enableServerOutput(orclConn) :
	orclConn.createStatement().execute("begin dbms_output.enable; end;")
	
def disableServerOutput(orclConn) :
	orclConn.createStatement().execute("begin dbms_output.disable; end;")

def getServerOutput(orclConn) :
	global lastConn, getLinesStmt
	if orclConn != lastConn :
		lastConn = orclConn
		getLinesStmt = orclConn.prepareCall(getLinesSql);
		getLinesStmt.registerIndexTableOutParameter(1, 1000, oracle.jdbc.OracleTypes.VARCHAR, 255)
		getLinesStmt.registerOutParameter(2, java.sql.Types.INTEGER)
	getLinesStmt.setInt(2, 1000);
	getLinesStmt.execute()
	lines = []
	array = getLinesStmt.getOraclePlsqlIndexTable(1)
	for i in range(getLinesStmt.getInt(2)) :
		if array[i] : lines.append(array[i].stringValue())
	return lines

def pauseMView(orclConn):
	stmt = orclConn.prepareCall("begin :1 := cwms_util.pause_mv_refresh(:2, :3); end;")
	stmt.registerOutParameter(1, oracle.jdbc.OracleTypes.ROWID)
	stmt.setString(2, "mv_cwms_ts_id")
	stmt.setString(3, "Inserting TSIDS from LoadExtractPostInfo.py")
	stmt.execute()
	pause_handle = stmt.getROWID(1);
	stmt.close()
	return pause_handle;

def resumeMView(orclConn, pause_handle):
	stmt = orclConn.prepareCall("begin cwms_util.resume_mv_refresh(:1); end;")
	stmt.setROWID(1, pause_handle);
	stmt.execute()
	stmt.close()
	
#----------------#
# Get user input #
#----------------#
#connStr  = raw_input("\nEnter DB Connection String (user/pass@tnsName)\n-->")
#fileName = raw_input("\nEnter name of data file\n-->")
connStr  = "cwms_20[q0cwmspd]/thenewdb06@q0mdp"
fileName = "NWD-ExtractPostInfo.txt"
# fileName = "HEC-ExtractPostInfo.txt"

#-------------------------#		
# Connect to the database #
#-------------------------#		
username, other   = connStr.split("/")
password, tnsName = other.split("@") 
try :
	username, sessionuser = username[:-1].split("[")
except :
	sessionuser = username
dbUrl = "jdbc:oracle:oci:@%s" % tnsName 
orclDS = oracle.jdbc.pool.OracleDataSource()
orclDS.setURL(dbUrl);
orclDS.setUser(username)
orclDS.setPassword(password)
orclDS.setConnectionCachingEnabled(TRUE)
orclConn = orclDS.getConnection()
if sessionuser != username :
	for i in range(10) :
		proxyForUser(orclConn, sessionuser)
orclConn.setAutoCommit(FALSE)
if serverOutput : enableServerOutput(orclConn)

createXchgSetStmt  = orclConn.prepareCall(createXchgSetSql)
mapTsInXchgSetStmt = orclConn.prepareCall(mapTsInXchgSetSql)
getDssXchgSetsStmt = orclConn.prepareCall(getDssXchgSetsSql)


lineNum = 0
actionCount = 0
pause_handle = None
try :
	getDssXchgSetsStmt.registerOutParameter(1, oracle.jdbc.OracleTypes.CLOB)
	t1 = time.time()
	getDssXchgSetsStmt.execute()
	clob = getDssXchgSetsStmt.getClob(1);
	t2 = time.time()
	print "Retrieved %d bytes in %f seconds." % (clob.length(), (t2 - t1))
	f = open("dataexchange.xml", "w");
	f.write(clob.getSubString(1, clob.length()))
	f.close()
	sys.exit()
	
	f = open(fileName, "r")
	lines = f.read().split("\n")
	f.close()
	pause_handle = pauseMView(orclConn)
	office = ""
	lastCwmsId = ""
	for line in lines :
		line = line.strip()
		lcLine = line.lower()
		lineNum += 1
		# if lineNum > 5 : break
		print "%d : %s" % (lineNum, line)
		if not line : continue
		if lcLine.startswith("officeid=") : office = line.split("=", 1)[1]
		if not office : continue
		elif lcLine.startswith("xchgset=") :
			fields = map(string.strip, line.split("=")[1].strip().split(";"))
			pos = fields[0].find("/", 2)
			dss_filemgr_url = fields[0][:pos]
			dss_file_name   = fields[0][pos:]
			dss_xchg_set_id = fields[1]
			description     = fields[2]
			createXchgSetStmt.registerOutParameter(1, java.sql.Types.INTEGER)
			createXchgSetStmt.setString(2, dss_xchg_set_id)
			createXchgSetStmt.setString(3, description)
			createXchgSetStmt.setString(4, dss_filemgr_url)
			createXchgSetStmt.setString(5, dss_file_name)
			createXchgSetStmt.setNull(6, java.sql.Types.VARCHAR)
			createXchgSetStmt.setInt(7, 0)
			if office.upper == "HQ" :
				createXchgSetStmt.setNull(8, java.sql.Types.VARCHAR)
			else :
				createXchgSetStmt.setString(8, office)
			try :
				createXchgSetStmt.execute()
				if serverOutput :
					for line in getServerOutput(orclConn) : print line
				setCode = createXchgSetStmt.getInt(1)
				mapTsInXchgSetStmt.setInt(1, setCode)
				mapTsInXchgSetStmt.setString(8, office)
				orclConn.commit()
			except java.sql.SQLException, e :
				if serverOutput :
					for line in getServerOutput(orclConn) : print line
				msg = "%s" % e.getMessage()
				if msg.find("ITEM_ALREADY_EXISTS") != -1 :
					print "Exchange set %s already exits." % dss_xchg_set_id
					for i in range(1, 100) :
						setName = "%s-%d" % (dss_xchg_set_id, i)
						print "...trying %s" % setName
						createXchgSetStmt.setString(3, setName)
						try :
							createXchgSetStmt.execute()
							if serverOutput :
								for line in getServerOutput(orclConn) : print line
							dss_xchg_set_id = setName
							setCode = createXchgSetStmt.getInt(1)
							mapTsInXchgSetStmt.setInt(1, setCode)
							mapTsInXchgSetStmt.setString(8, office)
							orclConn.commit()
							break
						except java.sql.SQLException, e :
							if serverOutput :
								for line in getServerOutput(orclConn) : print line
							msg = "%s" % e.getMessage()
							if msg.find("ITEM_ALREADY_EXISTS") == -1 :
								break
					else :
						print "...giving up"
						setCode = None
				else :
					setCode = None
					print e.getMessage()
			if setCode :
				print "CREATED %s-->%s%s" % (dss_xchg_set_id, dss_filemgr_url, dss_file_name) 
		elif lcLine.startswith("xchgmap=") :
			if not setCode :
				print "Skipping..."
				continue
			fields = map(string.strip, line.split("=", 1)[1].strip().split(";"))
			if fields[0].startswith("/") :
				dssPathname, cwmsId = fields[:2]
			else :
				cwmsId, dssPathname = fields[:2]
			if cwmsId == lastCwmsId : orclConn.commit()
			lastCwmsId = cwmsId
			originalDssPathname = dssPathname
			for i in range(2, len(fields)) : 
				key, val = map(string.strip, fields[i].split("="))
				if key.strip().lower() == "type" :
					originalType = val 
					if originalType.upper() == "PER-MAX" :
						val = "INST-VAL"
						pathParts = dssPathname.split("/")
						if pathParts[3].upper().find("MAX") == -1 :
							pathParts[3] += "-MAX"
							dssPathname = "/".join(pathParts)
					elif originalType.upper() == "PER-MIN" :
						val = "INST-VAL"
						pathParts = dssPathname.split("/")
						if pathParts[3].upper().find("MIN") == -1 :
							pathParts[3] += "-MIN"
							dssPathname = "/".join(pathParts)
					elif originalType.upper() == "Unk" :
						val = "INST-VAL"
						pathParts = dssPathname.split("/")
						if pathParts[3].upper().find("CONST") == -1 :
							pathParts[3] += "-CONST"
							dssPathname = "/".join(pathParts)
					if val != originalType :
						print "WARNING : Changed DSS Parameter Types"
						print "...OLD = %s" % originalType
						print "...NEW = %s" % val
					mapTsInXchgSetStmt.setString(4, val) 
				elif key.strip().lower() == "units" : 
					mapTsInXchgSetStmt.setString(5, val)
				else :
					raise Exception, "Invalid keyword: %s" % line
			if dssPathname != originalDssPathname :
				print "WARNING : Changed DSS Pathname"
				print "...OLD = %s" % originalDssPathname
				print "...NEW = %s" % dssPathname
			mapTsInXchgSetStmt.setString(2, cwmsId)
			mapTsInXchgSetStmt.setString(3, dssPathname)
			mapTsInXchgSetStmt.setNull(6, java.sql.Types.VARCHAR)
			mapTsInXchgSetStmt.setNull(7, java.sql.Types.VARCHAR)
			try : 
				mapTsInXchgSetStmt.execute()
				if serverOutput :
					for line in getServerOutput(orclConn) : print line
				orclConn.commit()
	        	except java.sql.SQLException, e :
				if serverOutput :
					for line in getServerOutput(orclConn) : print line
				print e.getMessage()			        
finally :
	if pause_handle : resumeMView(orclConn, pause_handle)
	try    : 
		orclConn.commit()
		if serverOutput :
			for line in getServerOutput(orclConn) : print line
	except : 
		pass
	createXchgSetStmt.close()
	mapTsInXchgSetStmt.close()
	if sessionuser != username :
		orclConn.close(oracle.jdbc.OracleConnection.PROXY_SESSION)
	orclConn.close()

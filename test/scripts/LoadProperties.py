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
setPropertiesSql    = "begin :1 := cwms_properties.set_properties(:2); end;"
getPropertiesSql    = "begin cwms_properties.get_properties(:1,:2); end;"  
getPropertiesXmlSql = "begin :1 := cwms_properties.get_properties_xml(:2); end;"  
getPropertySql      = "begin :1 := cwms_properties.get_property(:2, :3, :4); end;"  
setPropertySql      = "begin cwms_properties.set_property(:1, :2, :3, :4, :5); end;"  

#connStr  = "cwms_20/thenewdb06@q0mdp"
connStr  = "cwms_20/thenewdb06@155.83.200.66:1521:q0mdp"
fileName = "t:/out.txt"


field_separator  = chr(29) # ASCII group separator, use for field separator
record_separator = chr(30) # ASCII record separator

def arrayToStr(array) :
	text_rows = []
	for row in array : text_rows.append(field_separator.join(row))
	return record_separator.join(text_rows)
	
#-------------------------#		
# Connect to the database #
#-------------------------#		
username, other   = connStr.split("/")
password, tnsName = other.split("@")
if tnsName.find(":") == -1 : 
	dbUrl      = "jdbc:oracle:oci:@%s" % tnsName
else : 
	dbUrl      = "jdbc:oracle:thin:@%s" % tnsName
jdbcDriver = java.sql.DriverManager.registerDriver(oracle.jdbc.driver.OracleDriver());
jdbcConn   = java.sql.DriverManager.getConnection(dbUrl, username, password);
jdbcConn.setAutoCommit(FALSE)

setPropertiesStmt    = jdbcConn.prepareCall(setPropertiesSql)
getPropertiesStmt    = jdbcConn.prepareCall(getPropertiesSql)
getPropertiesXmlStmt = jdbcConn.prepareCall(getPropertiesXmlSql)
getPropertyStmt      = jdbcConn.prepareCall(getPropertySql)
setPropertyStmt      = jdbcConn.prepareCall(setPropertySql)

enableStmt = jdbcConn.prepareCall("begin dbms_output.enable(:1); end;")
enableStmt.setInt(1, 32000)
enableStmt.execute()
enableStmt.close()

showSql = \
'''
declare
   l_line varchar2(255);
   l_done number;
   l_buffer long;
begin
   loop
      exit when length(l_buffer) + 255 > :1 or l_done = 1;
      dbms_output.get_line(l_line, l_done);
      l_buffer := l_buffer || l_line || chr(10);
   end loop;
   :2 := l_done;
   :3 := l_buffer;
end;
'''

def show_output() :
	showStmt = jdbcConn.prepareCall(showSql)
	showStmt.setInt(1, 32000)
	showStmt.registerOutParameter(2, java.sql.Types.INTEGER)
	showStmt.registerOutParameter(3, java.sql.Types.VARCHAR)
	while TRUE :
		showStmt.execute()
		print showStmt.getString(3)
		if showStmt.getInt(2) : break
	showStmt.close()

office_id="HQ"
properties_dirs = []
for host in ("hec64", "hec65", "hec66") :
	for user in ("q0cwmspd", "q0cwmsts") :
		properties_dirs.append(os.path.join("properties", host, user))
properties = []
try :
	try :
		for properties_dir in properties_dirs :
			for fname in os.listdir(properties_dir) :
				if fname.lower().endswith(".properties") :
					pathname = os.path.join(properties_dir, fname)
					if not os.path.isfile(pathname) : continue
					category = ".".join(
						os.path.join(
						properties_dir, os.path.splitext(fname)[0]).split(os.sep)[1:])
					print "Processing category %s" % category
					f = open(pathname, 'r')
					lines = f.read().split("\n")
					f.close()
					for line in lines :
						line = line.strip()
						if not line : continue
						if line.startswith("#") : continue
						try :
							key, value = map(string.strip, line.split("="))
							properties.append([office_id, category, key, value, ''])
						except :
							continue
		_str = arrayToStr(properties)
		print len(_str)
		print properties[-1]
		print len(properties)
		print len(_str.split(record_separator))
		setPropertiesStmt.registerOutParameter(1, java.sql.Types.INTEGER); 
		setPropertiesStmt.setString(2, _str)
		t1 = time.time() 
		setPropertiesStmt.execute();
		t2 = time.time()
		show_output()
		print "%d properties set successfully in %f seconds" % \
			(setPropertiesStmt.getInt(1), t2 - t1);
		
		properties = [
			["HQ", "*", "*"],
		]
		getPropertiesStmt.registerOutParameter(1, oracle.jdbc.OracleTypes.CURSOR)
		_str = arrayToStr(properties)
		getPropertiesStmt.setString(2, _str)
		t1 = time.time()
		getPropertiesStmt.execute()
		rs = getPropertiesStmt.getCursor(1)
		i = 0
		while rs.next() :
			i += 1
			office_id = rs.getString(1)
			category = rs.getString(2)
			id = rs.getString(3)
			value = rs.getString(4)
			comment = rs.getString(5)
			# print "%s/%s/%s=%s # %s" % (office_id, category, id, value, comment)
		rs.close();
		t2 = time.time()
		print "%d properties successfully retrieved in %f seconds" % \
			(i, t2 - t1)
		
		getPropertiesXmlStmt.registerOutParameter(1, oracle.jdbc.OracleTypes.CLOB)
		getPropertiesXmlStmt.setString(2, arrayToStr(properties))
		t1 = time.time()
		getPropertiesXmlStmt.execute()
		t2 = time.time()
		show_output()
		clob = getPropertiesXmlStmt.getClob(1)
		xmlFilename = "properties.xml"
		f = open(xmlFilename, 'w')
		f.write(clob.getSubString(1, clob.length()))
		f.close()
		print "%d bytes retrieved in %f seconds and written to %s" % \
			(clob.length(), t2 - t1, xmlFilename)
		clob.freeTemporary()

		office_id = "HQ"
		category  = "hec65.q0cwmsts.dbi"
		id        = "wcds.dbi.ConnectUsingUrl"  
		getPropertyStmt.registerOutParameter(1, java.sql.Types.VARCHAR);
		getPropertyStmt.setString(2, office_id);
		getPropertyStmt.setString(3, category);
		getPropertyStmt.setString(4, id);
		t1 = time.time()
		getPropertyStmt.execute();
		value = getPropertyStmt.getString(1);
		t2 = time.time()
		print "single property %s/%s/%s=%s retrieved in %f seconds" % \
			(office_id, category, id, value, t2 - t1);
		setPropertyStmt.setString(1, office_id);
		setPropertyStmt.setString(2, category);
		setPropertyStmt.setString(3, id);
		setPropertyStmt.setString(4, "jdbc.oracle.oci@Q0MDP");
		setPropertyStmt.setString(5, "Changed on %s" % time.ctime());
		t1 = time.time()
		setPropertyStmt.execute();
		t2 = time.time()
		getPropertyStmt.execute();
		value = getPropertyStmt.getString(1);
		print "single property %s/%s/%s modified to %s in %f seconds" % \
			(office_id, category, id, value, t2 - t1);
		print "\nHere are the properties containing 'logfile' in a category containing 'cwmsts':"
		getPropertiesStmt.setString(2, arrayToStr([["HQ", "*cwmsts*", "*logfile*"]]))
		getPropertiesStmt.execute()
		rs = getPropertiesStmt.getCursor(1)
		i = 0
		while rs.next() :
			i += 1
			office_id = rs.getString(1)
			category = rs.getString(2)
			id = rs.getString(3)
			value = rs.getString(4)
			comment = rs.getString(5)
			print "\t%s\t%s\t%s\t%s\t%s" % (office_id, category, id, value, comment)
		rs.close();
		
		
	except :
		show_output()
		traceback.print_exc()
finally :
	setPropertiesStmt.close()
	getPropertiesStmt.close()
	jdbcConn.close()

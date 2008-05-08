import cwmsdb, java, jarray, oracle, sys, time

True, False = 1, 0

dbUrl      = 'jdbc:oracle:thin:@localhost:1521:q0mdp2'
username   = 'e1cwmsdbi'
password   = 'cwms20db'
proxyusr   = 'e1cwmspd'
connProps  = java.util.Properties()
cli        = cwmsdb.ConnectionLoginInfoImpl(dbUrl, username, password)
conn       = cwmsdb.ConnectionPool.getInstance().getConnection(cli)
timeFormat = java.text.SimpleDateFormat("yyyy/MM/dd-HH:mm:ss")

connProps.setProperty("PROXY_USER_NAME", proxyusr)
conn.openProxySession(oracle.jdbc.OracleConnection.PROXYTYPE_USER_NAME, connProps)
cts = cwmsdb.CwmsTsJdbc(conn);
#
# create the data
#
cal = java.util.GregorianCalendar()
cal.clear()
yr, mo, da, hr, mi, se = 2006, 2, 1, 0, 15, 0
cal.set(yr, mo-1, da, hr, mi, se)
_times   = []
_values  = []
_quality = []

startTime = cal.getTimeInMillis()
for i in range(24) :
	if i < 3 or (i > 9 and i < 13) :
		pass
	else :
		_times.append(cal.getTimeInMillis())
		_values.append(i)
		if i > 19 :
			_quality.append(5)
		else :
			_quality.append(0)
	endTime = cal.getTimeInMillis()
	cal.add(java.util.Calendar.HOUR_OF_DAY, 1)


tsids   = []
units   = []
times   = []
values  = []
quality = []
count   = []

tsids.append('Tester-id1.Flow.Inst.0.0.test')
units.append('kcfs')
times.append(_times)
values.append(_values)
quality.append(_quality)
count.append(len(_times))

tsids.append('Tester-id2.Flow.Inst.1Hour.0.test')
units.append('kcfs')
times.append(_times)
values.append(_values)
quality.append(_quality)
count.append(len(_times))

tsids.append('Tester-id3.Flow.Inst.0.0.test')
units.append('cms')
times.append(_times)
values.append(_values)
quality.append(_quality)
count.append(len(_times))

tsids.append('Tester-id4.Flow.Inst.1Hour.0.test')
units.append('cms')
times.append(_times)
values.append(_values)
quality.append(_quality)
count.append(len(_times))
#
# delete existing data
# 
delete = False
if delete :
	print "\nDeleting data"
	start_time = time.time()
	for tsid in tsids :
		try :
			cts.deleteAll(None, tsid)
			print "-->Deleted %s" % tsid
		except :
			print "-->Could not delete %s" % tsid
	conn.commit()	       
	end_time = time.time()
	print "Data deleted in %f seconds." % (end_time - start_time) 
#
# store the data
# 
store = True
if store :
	print "\nStoring data"
	start_time = time.time()
	cts.store(
		None,
		tsids,
		units,
		times,
		values,
		quality,
		count,
		"DELETE INSERT",
		True,
		None)
	
	conn.commit()	       
	end_time = time.time()
	print "Data stored in %f seconds." % (end_time - start_time) 

units[2] = 'cfs'
units[3] = None
#
# retrieve data in a loop
# 
print "\nRetrieving data in loop"
tsid = jarray.zeros(1, java.lang.String)
unit = jarray.zeros(1, java.lang.String)
elapsedTime = 0
for i in range(len(tsids)) : 
	tsid[0] = tsids[i].upper()
	print tsid[0]
	unit[0] = units[i]
	start_time = time.time()
	rs = cts.retrieve(
		None,
		tsid,
		unit,
		java.sql.Timestamp(startTime),
		java.sql.Timestamp(endTime),
		'UTC',
		False,
		True,
		True,
		False,
		False,
		None,
		True)
	end_time = time.time()
	elapsedTime += end_time - start_time
		
	print tsid[0], unit[0]
	md = rs.getMetaData()
	sys.stdout.write("\t")
	for i in range(md.getColumnCount()) :
		sys.stdout.write("%s, " % md.getColumnName(i+1))
	print
	while rs.next() :
		sqlTS   = rs.getTimestamp(1)
		sqlVal  = rs.getDouble(2)
		nullVal = rs.wasNull()
		sqlQual = rs.getInt(3)
		if nullVal :
			print "\t%s, <null>, %d" % (timeFormat.format(sqlTS.getTime()), sqlQual)
		else :
			print "\t%s, %f, %d" % (timeFormat.format(sqlTS.getTime()), sqlVal, sqlQual)
	rs.close()
	print

print "Data retrieved in %f seconds." % elapsedTime
	
startTimes = []
endTimes   = []
for i in range(len(tsids)) :
	startTimes.append(java.sql.Timestamp(startTime))
	endTimes.append(java.sql.Timestamp(endTime))
#
# retrieve data using nested cursor
# 		
print "\nRetrieving data with nested cursor"
start_time = time.time()
rs = cts.retrieve(
	None,
	tsids,
	units,
	startTimes,
	endTimes,
	'UTC',
	False,
	True,
	True,
	False,
	False,
	None,
	True)

end_time = time.time()	

md = rs.getMetaData()
for i in range(md.getColumnCount()) :
	sys.stdout.write("%s, " % md.getColumnName(i+1))
print
while rs.next() :
	seq  = rs.getInt(1)
	tsid = rs.getString(2)
	units = rs.getString(3)
	start = rs.getTimestamp(4)
	end = rs.getTimestamp(5)
	tz = rs.getString(6)
	rs2 = rs.getCursor(7)
	print "\n%d %s, %s, %s, %s, %s" % (seq, tsid, units, timeFormat.format(start.getTime()), timeFormat.format(end.getTime()), tz)
	md = rs2.getMetaData()
	sys.stdout.write("\t")
	for i in range(md.getColumnCount()) :
		sys.stdout.write("%s, " % md.getColumnName(i+1))
	print
	while rs2.next():
		sqlTS   = rs2.getTimestamp(1)
		sqlVal  = rs2.getDouble(2)
		nullVal = rs2.wasNull()
		sqlQual = rs2.getInt(3)
		if nullVal :
			print "\t%s, <null>, %d" % (timeFormat.format(sqlTS.getTime()), sqlQual)
		else :
			print "\t%s, %f, %d" % (timeFormat.format(sqlTS.getTime()), sqlVal, sqlQual)
	rs2.close()

rs.close()	

print "Data retrieved in %f seconds." % (end_time - start_time)
